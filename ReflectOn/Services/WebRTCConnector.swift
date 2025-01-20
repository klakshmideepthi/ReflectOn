import Foundation
import WebRTC
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class WebRTCConnector: NSObject, Connector, @unchecked Sendable, RTCPeerConnectionDelegate {

    @MainActor public private(set) var onDisconnect: (@Sendable () -> Void)? = nil
    public let events: AsyncThrowingStream<ServerEvent, Error>

    private let stream: AsyncThrowingStream<ServerEvent, Error>.Continuation
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private let request: URLRequest
    
    private var isCleanedUp = false

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    public init(connectingTo request: URLRequest) async throws {
        self.request = request
        (events, stream) = AsyncThrowingStream.makeStream(of: ServerEvent.self)
        super.init()

        do {
            try await self.connect()
        } catch {
            stream.finish(throwing: error)
        }
    }

    deinit {
            cleanup()
            print("WebRTCConnector deinitialized")
        }
        
        public func disconnect() {
            cleanup()
        }
        
    private func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true
        
        // Close data channel first
        let channel = dataChannel
        dataChannel = nil
        channel?.delegate = nil
        channel?.close()
        
        // Close peer connection
        let connection = peerConnection
        peerConnection = nil
        connection?.delegate = nil
        connection?.close()
        
        // Finish stream
        stream.finish()
        
        // Handle disconnect callback on MainActor
        Task { @MainActor in
            let handler = onDisconnect
            onDisconnect = nil
            handler?()
        }
    }

    public func send(event: ClientEvent) async throws {
        guard let dataChannel = dataChannel, dataChannel.readyState == .open else {
            throw RealtimeAPIError.invalidMessage
        }

        let message = try encoder.encode(event)

        let buffer = RTCDataBuffer(data: message, isBinary: false)
        dataChannel.sendData(buffer)
    }

    @MainActor public func onDisconnect(_ action: (@Sendable () -> Void)?) {
        onDisconnect = action
    }

    private func receiveMessage(_ message: String) {
        self.stream.yield(with: Result { try self.decoder.decode(ServerEvent.self, from: message.data(using: .utf8)!) })
    }

    private func connect() async throws {
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue])

        // Gather ICE candidates
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]

        // Create a new RTCPeerConnection
        let factory = RTCPeerConnectionFactory()

        guard let pc = factory.peerConnection(with: config, constraints: constraints, delegate: self) else {
            throw RealtimeAPIError.invalidMessage
        }
        
        self.peerConnection = pc

        // Create a data channel
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.isOrdered = true

        guard let dc = pc.dataChannel(forLabel: "oai-events", configuration: dataChannelConfig) else { // Unwrapped pc
            throw RealtimeAPIError.invalidMessage
        }

        dc.delegate = self
        self.dataChannel = dc

        // Add local audio track for microphone input
        if let audioTrack = createAudioTrack(factory: factory) {
            pc.add(audioTrack, streamIds: ["audioStream"]) // Unwrapped pc
        }

        // Create an offer
        let offerOptions = RTCMediaConstraints(mandatoryConstraints: ["OfferToReceiveAudio": "true"], optionalConstraints: nil)
        let localSDP = try await self.createOffer(connection: pc, constraints: offerOptions) // Unwrapped pc
        try await pc.setLocalDescription(localSDP) // Unwrapped pc

        // Send offer to server and get answer
        let answerSDP = try await self.sendOffer(offer: localSDP, request: request)

        // Set remote description
        try await pc.setRemoteDescription(answerSDP) // Unwrapped pc
    }

    private func createAudioTrack(factory: RTCPeerConnectionFactory) -> RTCAudioTrack? {
        let audioConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "googEchoCancellation": "true",
                "googAutoGainControl": "true",
                "googNoiseSuppression": "true",
                "googHighpassFilter": "true"
            ],
            optionalConstraints: nil
        )
        let audioSource = factory.audioSource(with: audioConstraints)
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio0")
        return audioTrack
    }

    private func createOffer(connection: RTCPeerConnection, constraints: RTCMediaConstraints) async throws -> RTCSessionDescription {
        typealias createOfferContinuation = CheckedContinuation<RTCSessionDescription, Error>

        return try await withCheckedThrowingContinuation { (continuation: createOfferContinuation) in
            connection.offer(for: constraints) { (sdp, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sdp = sdp else {
                    continuation.resume(throwing: NSError(domain: "RTCPeerConnection", code: 0, userInfo: [NSLocalizedDescriptionKey: "SDP is nil"]))
                    return
                }

                continuation.resume(returning: sdp)
            }
        }
    }

    private func sendOffer(offer: RTCSessionDescription, request: URLRequest) async throws -> RTCSessionDescription {
        var request = request
        request.httpMethod = "POST"
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = offer.sdp.data(using: .utf8)

        typealias sendOfferContinuation = CheckedContinuation<RTCSessionDescription, Error>

        return try await withCheckedThrowingContinuation { (continuation: sendOfferContinuation) in
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data = data else {
                    continuation.resume(throwing: NSError(domain: "HTTPClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                    return
                }

                guard let answerSDPString = String(data: data, encoding: .utf8) else {
                    continuation.resume(throwing: NSError(domain: "HTTPClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid SDP data"]))
                    return
                }

                let answerSDP = RTCSessionDescription(type: .answer, sdp: answerSDPString)
                continuation.resume(returning: answerSDP)
            }
            task.resume()
        }
    }

    // MARK: - RTCPeerConnectionDelegate

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCPeerConnectionState) {
        print("Peer Connection State:", stateChanged.rawValue)
        if stateChanged == .closed || stateChanged == .failed || stateChanged == .disconnected {
                    cleanup()
                }
    }

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("Peer Connection should negotiate")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("Received remote stream (deprecated)")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("Removed remote stream (deprecated)")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE Connection State:", newState.rawValue)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("Signaling State:", stateChanged.rawValue)
        switch stateChanged {
        case .closed:
            stream.finish()
        default:
            break
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        // Send the candidate to the signaling server
        print("Generated ICE candidate:", candidate)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("Removed ICE candidates")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("Data channel opened")
        dataChannel.delegate = self
        self.dataChannel = dataChannel
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChangeStandardizedIceConnectionState newState: RTCIceConnectionState) {
        print("Standardized ICE Connection State:", newState.rawValue)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("ICE Gathering State:", newState.rawValue)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        if let track = rtpReceiver.track {
            print("Received remote track:", track.kind)
            if track.kind == "audio" {
                DispatchQueue.main.async {
                    // Create an audio player on the main thread if needed
                }
            }
        }
    }
}

// MARK: - RTCDataChannelDelegate

extension WebRTCConnector: RTCDataChannelDelegate {
    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("Data channel state:", dataChannel.readyState.rawValue)
        if dataChannel.readyState == .closed {
                    cleanup()
                }
    }

    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if buffer.isBinary {
            print("Received binary data")
        } else {
            guard let message = String(data: buffer.data, encoding: .utf8) else { return }
            self.receiveMessage(message)
        }
    }
}

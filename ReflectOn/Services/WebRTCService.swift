import SwiftUI
import WebRTC
import AVFoundation
import FirebaseFunctions
import FirebaseAuth
import Firebase


class WebRTCService: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var eventTypeStr: String = ""
    
    @Published var conversation: [ConversationItem] = []
    @Published var outgoingMessage: String = ""
    
    private var conversationMap: [String : ConversationItem] = [:]
    
    // Model & session config
    private var modelName: String = "gpt-4o-mini-realtime-preview-2024-12-17"
    private var systemInstructions: String = ""
    private var voice: String = "alloy"
    
    // WebRTC references
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var audioTrack: RTCAudioTrack?
    
    // [New or Updated] Firebase Functions
    private lazy var functions = Functions.functions()
    
    // For demonstration, you might track a "sessionId" for saving transcripts
    // This could be your own way of referencing conversation sessions.
    private var currentSessionId: String = UUID().uuidString
    
    // Add these properties at the top of the class
    private var currentUserTranscript: String = ""
    private var currentAssistantTranscript: String = ""
    
    override init() {
        super.init()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    /// Check if microphone permission is granted. If undetermined, it will request.
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }
    
    /// 1) Fetch ephemeral key from Firebase using `getEphemeralKey`.
    /// 2) Start a WebRTC connection with that key.
    func startConnection(
        modelName: String,
        systemMessage: String,
        voice: String
    ) {
        // Clear old conversation
        conversation.removeAll()
        conversationMap.removeAll()
        
        self.modelName = modelName
        self.systemInstructions = systemMessage
        self.voice = voice
        self.connectionStatus = .connecting
        
        
        // Get ephemeral key from Firebase
        let functions = Functions.functions()
        print("Calling getEphemeralKey function...")
        
        // Define request data structure
        let requestData: [String: String] = [
            "model": modelName,
            "voice": voice
        ]
        functions.httpsCallable("getEphemeralKey").call(requestData) { [weak self] result, error in
                    if let error = error as NSError? {
                        print("Error getting ephemeral key: \(error.localizedDescription)")
                        if let details = error.userInfo[FunctionsErrorDetailsKey] {
                            print("Error details: \(details)")
                        }
                        DispatchQueue.main.async {
                            self?.connectionStatus = .disconnected
                        }
                        return
                    }
                    
                    guard let resultData = result?.data as? [String: Any],
                          let clientSecret = resultData["client_secret"] as? [String: Any],
                          let ephemeralKey = clientSecret["value"] as? String else {
                        print("Invalid response format from getEphemeralKey")
                        if let data = result?.data {
                            print("Received data structure: \(data)")
                        }
                        DispatchQueue.main.async {
                            self?.connectionStatus = .disconnected
                        }
                        return
                    }
                    
                    print("Successfully received ephemeral key")
                    DispatchQueue.main.async {
                        self?.setupAndOffer(ephemeralKey: ephemeralKey)
                    }
                }
    }
    
    /// Stop the current WebRTC connection and save transcripts.
    func stopConnection() {
        // Save transcripts before closing connection
        saveTranscriptsToFirebase()
        
        peerConnection?.close()
        peerConnection = nil
        dataChannel = nil
        audioTrack = nil
        connectionStatus = .disconnected
        
        // Reset transcripts
        currentUserTranscript = ""
        currentAssistantTranscript = ""
    }
    
    /// Toggle local microphone.
    func setMicrophoneEnabled(_ enabled: Bool) {
        audioTrack?.isEnabled = enabled
    }
    
    /// Sends a custom "conversation.item.create" event
    func sendMessage() {
        guard let dc = dataChannel,
              !outgoingMessage.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }
        
        let realtimeEvent: [String: Any] = [
            "type": "conversation.item.create",
            "item": [
                "type": "message",
                "role": "user",
                "content": [
                    [
                        "type": "input_text",
                        "text": outgoingMessage
                    ]
                ]
            ]
        ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: realtimeEvent) {
            let buffer = RTCDataBuffer(data: jsonData, isBinary: false)
            dc.sendData(buffer)
            self.outgoingMessage = ""
            createResponse()
        }
    }
    
    /// Sends a "response.create" event
    func createResponse() {
        guard let dc = dataChannel else { return }
        
        let realtimeEvent: [String: Any] = [ "type": "response.create" ]
        if let jsonData = try? JSONSerialization.data(withJSONObject: realtimeEvent) {
            let buffer = RTCDataBuffer(data: jsonData, isBinary: false)
            dc.sendData(buffer)
        }
    }
    
    /// Updates session configuration with the latest instructions and voice.
    func sendSessionUpdate() {
        guard let dc = dataChannel, dc.readyState == .open else {
            print("Data channel is not open. Cannot send session.update.")
            return
        }
        
        let sessionUpdate: [String: Any] = [
            "type": "session.update",
            "session": [
                "modalities": ["text", "audio"],  // Enable both text and audio
                "instructions": systemInstructions,
                "voice": voice,
                "input_audio_format": "pcm16",
                "output_audio_format": "pcm16",
                "input_audio_transcription": [
                    "model": "whisper-1"
                ],
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "prefix_padding_ms": 300,
                    "silence_duration_ms": 500,
                    "create_response": true
                ],
                "max_response_output_tokens": "inf"
            ]
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sessionUpdate)
            let buffer = RTCDataBuffer(data: jsonData, isBinary: false)
            dc.sendData(buffer)
            print("session.update event sent.")
        } catch {
            print("Failed to serialize session.update JSON: \(error)")
        }
    }
    
    // MARK: - Private Methods

    /// [New] Called after ephemeral key has been retrieved. Sets up local PC and does offer/answer exchange.
    private func setupAndOffer(ephemeralKey: String) {
        setupPeerConnection()
        setupLocalAudio()
        configureAudioSession()
        
        guard let peerConnection = peerConnection else {
            self.connectionStatus = .disconnected
            return
        }
        
        // Create a Data Channel
        let config = RTCDataChannelConfiguration()
        config.isOrdered = true
        if let channel = peerConnection.dataChannel(forLabel: "oai-events", configuration: config) {
            dataChannel = channel
            dataChannel?.delegate = self
        }
        
        // Create an SDP offer
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: ["levelControl": "true"],
            optionalConstraints: nil
        )
        peerConnection.offer(for: constraints) { [weak self] sdp, error in
            guard
                let self = self,
                let sdp = sdp,
                error == nil
            else {
                print("Failed to create offer: \(String(describing: error))")
                DispatchQueue.main.async {
                    self?.connectionStatus = .disconnected
                }
                return
            }
            // Set local description
            peerConnection.setLocalDescription(sdp) { [weak self] error in
                guard let self = self, error == nil else {
                    print("Failed to set local description: \(String(describing: error))")
                    DispatchQueue.main.async {
                        self?.connectionStatus = .disconnected
                    }
                    return
                }
                
                Task {
                    do {
                        guard let localSdp = peerConnection.localDescription?.sdp else {
                            return
                        }
                        // [Updated] Post SDP offer to Realtime using ephemeralKey
                        let answerSdp = try await self.fetchRemoteSDP(ephemeralKey: ephemeralKey, localSdp: localSdp)
                        
                        // Set remote description
                        let answer = RTCSessionDescription(type: .answer, sdp: answerSdp)
                        peerConnection.setRemoteDescription(answer) { error in
                            DispatchQueue.main.async {
                                if let error {
                                    print("Failed to set remote description: \(error)")
                                    self.connectionStatus = .disconnected
                                } else {
                                    self.connectionStatus = .connected
                                }
                            }
                        }
                    } catch {
                        print("Error fetching remote SDP: \(error)")
                        DispatchQueue.main.async {
                            self.connectionStatus = .disconnected
                        }
                    }
                }
            }
        }
    }
    
    private func setupPeerConnection() {
        let config = RTCConfiguration()
        // config.iceServers = [...] if needed
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let factory = RTCPeerConnectionFactory()
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setMode(.videoChat)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to configure AVAudioSession: \(error)")
        }
    }
    
    private func setupLocalAudio() {
        guard let peerConnection = peerConnection else { return }
        let factory = RTCPeerConnectionFactory()
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "googEchoCancellation": "true",
                "googAutoGainControl": "true",
                "googNoiseSuppression": "true",
                "googHighpassFilter": "true"
            ],
            optionalConstraints: nil
        )
        
        let audioSource = factory.audioSource(with: constraints)
        let localAudioTrack = factory.audioTrack(with: audioSource, trackId: "local_audio")
        
        peerConnection.add(localAudioTrack, streamIds: ["local_stream"])
        audioTrack = localAudioTrack
    }
    
    /// [Updated] Instead of apiKey, accept ephemeralKey to authenticate to OpenAI Realtime
    private func fetchRemoteSDP(ephemeralKey: String, localSdp: String) async throws -> String {
        let baseUrl = "https://api.openai.com/v1/realtime"
        guard let url = URL(string: "\(baseUrl)?model=\(modelName)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(ephemeralKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = localSdp.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "WebRTCService.fetchRemoteSDP",
                          code: code,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
        }
        
        guard let answerSdp = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "WebRTCService.fetchRemoteSDP",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Unable to decode SDP"])
        }
        
        return answerSdp
    }
    
    // MARK: - Handling JSON and Transcripts
    
    private func handleIncomingJSON(_ jsonString: String) {
        print("Received JSON:\n\(jsonString)\n")
        
        guard let data = jsonString.data(using: .utf8),
              let rawEvent = try? JSONSerialization.jsonObject(with: data),
              let eventDict = rawEvent as? [String: Any],
              let eventType = eventDict["type"] as? String else {
            return
        }
        
        eventTypeStr = eventType
        
        switch eventType {
        case "conversation.item.created":
            if let item = eventDict["item"] as? [String: Any],
               let itemId = item["id"] as? String,
               let role = item["role"] as? String
            {
                let text = (item["content"] as? [[String: Any]])?.first?["text"] as? String ?? ""
                let newItem = ConversationItem(id: itemId, role: role, text: text)
                
                conversationMap[itemId] = newItem
                if role == "assistant" || role == "user" {
                    conversation.append(newItem)
                }
            }
            
        case "response.audio_transcript.delta":
            // partial transcript for assistant's message
            if let itemId = eventDict["item_id"] as? String,
               let delta = eventDict["delta"] as? String
            {
                if var convItem = conversationMap[itemId] {
                    convItem.text += delta
                    conversationMap[itemId] = convItem
                    if let idx = conversation.firstIndex(where: { $0.id == itemId }) {
                        conversation[idx].text = convItem.text
                    }
                }
            }
            
        case "response.audio_transcript.done":
            // final transcript for assistant's message
            if let itemId = eventDict["item_id"] as? String,
               let transcript = eventDict["transcript"] as? String
            {
                if var convItem = conversationMap[itemId] {
                    convItem.text = transcript
                    conversationMap[itemId] = convItem
                    if let idx = conversation.firstIndex(where: { $0.id == itemId }) {
                        conversation[idx].text = transcript
                    }
                }
                currentAssistantTranscript += transcript
            }
            
        case "conversation.item.input_audio_transcription.completed":
            // final transcript for user's audio input
            if let itemId = eventDict["item_id"] as? String,
               let transcript = eventDict["transcript"] as? String
            {
                if var convItem = conversationMap[itemId] {
                    convItem.text = transcript
                    conversationMap[itemId] = convItem
                    if let idx = conversation.firstIndex(where: { $0.id == itemId }) {
                        conversation[idx].text = transcript
                    }
                }
                print("*************** \(transcript)")
                currentUserTranscript += transcript
                print("*************** \(currentUserTranscript)")
            }
            
        default:
            break
        }
    }
    
    /// Saves both user and assistant transcripts together
    func saveTranscriptsToFirebase() {
        guard let user = Auth.auth().currentUser else {
            print("No authenticated user.")
            return
        }
        
        // Snapshot transcripts now, to avoid timing issues
        let userTranscriptSnapshot = currentUserTranscript
        let assistantTranscriptSnapshot = currentAssistantTranscript
        
        // Confirm we actually have content
        guard !userTranscriptSnapshot.isEmpty || !assistantTranscriptSnapshot.isEmpty else {
            print("No transcripts to save")
            return
        }
        
        user.getIDToken { token, error in
            guard let token = token, error == nil else {
                print("Error getting ID token:", error?.localizedDescription ?? "")
                return
            }
            
            // Now use the local snapshot
            let data: [String: Any] = [
                "sessionId": self.currentSessionId,
                "userTranscript": userTranscriptSnapshot,
                "assistantTranscript": assistantTranscriptSnapshot,
                "userId": user.uid,
                "timestamp": Date().timeIntervalSince1970
            ]
            print("Sending transcripts:", data)
            
            Functions.functions()
                .httpsCallable("transcribeAudio")
                .call(data) { result, error in
                    if let error = error as NSError? {
                        print("Error saving transcripts:", error.localizedDescription)
                        return
                    }
                    print("Transcripts saved successfully for sessionId=\(self.currentSessionId)")
                }
        }
    }
    
    // MARK: - Audio Interruptions
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("Audio session interruption began.")
            // Optionally mute if needed
        case .ended:
            print("Audio session interruption ended.")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    do {
                        try AVAudioSession.sharedInstance().setActive(true)
                        print("Resumed audio session after interruption.")
                    } catch {
                        print("Failed to resume audio session: \(error)")
                    }
                }
            }
        @unknown default:
            break
        }
    }
}

// MARK: - RTCPeerConnectionDelegate
extension WebRTCService: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if let remoteAudioTrack = stream.audioTracks.first {
            print("Received remote audio track: \(remoteAudioTrack.trackId)")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("ICE Connection State changed to: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {}
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        dataChannel.delegate = self
    }
}

// MARK: - RTCDataChannelDelegate
extension WebRTCService: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("Data channel state changed: \(dataChannel.readyState)")
        if dataChannel.readyState == .open {
            sendSessionUpdate()
        }
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel,
                     didReceiveMessageWith buffer: RTCDataBuffer) {
        guard let message = String(data: buffer.data, encoding: .utf8) else {
            return
        }
        DispatchQueue.main.async {
            self.handleIncomingJSON(message)
        }
    }
}

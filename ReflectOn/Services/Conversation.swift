import Foundation
import AVFoundation

@preconcurrency import AVFoundation

public enum ConversationError: Error {
    case sessionNotFound
    case converterInitializationFailed
}

@Observable
public final class Conversation: Sendable {
    // MARK: - Core
    let client: RealtimeAPI
    @MainActor private var cancelTask: (() -> Void)?
    private let errorStream: AsyncStream<ServerError>.Continuation

    // MARK: - Audio-Related Properties
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()

    /// We track which conversation item(s) are being played so we can handle interruption.
    private let queuedSamples = UnsafeMutableArray<String>()

    /// Converter for API → device format (24 kHz → device).
    private let apiConverter = UnsafeInteriorMutable<AVAudioConverter>()

    /// Converter for device → API format (device → 24 kHz).
    private let userConverter = UnsafeInteriorMutable<AVAudioConverter>()
    
    private var isCleanedUp = false

    /// 24 kHz, 1 channel, 16-bit PCM. This is what the Realtime API expects.
    private let desiredFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: 24000,
        channels: 1,
        interleaved: false
    )!

    // MARK: - Public Observables

    /// A stream of errors that occur during the conversation.
    public let errors: AsyncStream<ServerError>

    /// The unique ID of the conversation (once established).
    @MainActor public private(set) var id: String?

    /// The current session for this conversation (model, voice, instructions, etc.).
    @MainActor public private(set) var session: Session?

    /// A list of items in the conversation (messages, function calls, etc.).
    @MainActor public private(set) var entries: [Item] = []

    /// Whether the conversation is currently connected to the server.
    @MainActor public private(set) var connected: Bool = false

    /// Whether we are currently capturing from the user’s mic.
    @MainActor public private(set) var isListening: Bool = false

    /// Whether we are currently handling voice i/o (mic + playback).
    @MainActor public private(set) var handlingVoice: Bool = false

    /// Whether the user is currently speaking (only valid if using server VAD).
    @MainActor public private(set) var isUserSpeaking: Bool = false

    /// Whether the model is currently speaking (based on queued audio).
    @MainActor public private(set) var isPlaying: Bool = false

    /// Just the user/assistant messages (excluding function calls).
    @MainActor public var messages: [Item.Message] {
        entries.compactMap { entry in
            if case let .message(m) = entry { return m }
            return nil
        }
    }
    
    @MainActor public private(set) var onDisconnect: (@Sendable () -> Void)? = nil

    // MARK: - Init / Deinit

    private var eventTask: Task<Void, Never>?
    private var cleanupTask: Task<Void, Never>?
    
    private init(client: RealtimeAPI) {
        self.client = client
        (errors, errorStream) = AsyncStream.makeStream(of: ServerError.self)
        
        // Create event task with weak self
        eventTask = Task.detached { [weak self] in
            guard let self else { return }
            do {
                // Create local reference to avoid capturing self in loop
                let localClient = client
                for try await event in localClient.events {
                    // Use weak self in async context
                    await MainActor.run { [weak self] in
                        self?.handleEvent(event)
                    }
                }
            } catch {
                // Use weak self in async context
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    self.errorStream.yield(ServerError(
                        type: "stream_error",
                        code: nil,
                        message: "\(error)",
                        param: nil,
                        eventId: nil
                    ))
                }
            }
            // Use weak self in async context
            await MainActor.run { [weak self] in
                self?.connected = false
                self?.onDisconnect?()
            }
        }
    }
    
    deinit {
        print("Starting Conversation cleanup")
        cleanup()
        print("Conversation deinitialized")
    }
    
    private func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true
        
        // Cancel event task immediately
        eventTask?.cancel()
        eventTask = nil
        
        // Finish error stream
        errorStream.finish()
        
        // Create cleanup task with weak self
        cleanupTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            
            // Stop audio
            stopHandlingVoice()
            stopListening()
            
            // Clear tasks and handlers
            cancelTask?()
            cancelTask = nil
            onDisconnect = nil
            
            // Clear task reference
            cleanupTask = nil
        }
    }

    public convenience init(
        authToken token: String,
        model: String = "gpt-4o-mini-realtime-preview-2024-12-17"
    ) async throws {
        let api: RealtimeAPI
        api = try await RealtimeAPI.webRTC(authToken: token, model: model)
        self.init(client: api)
    }

    public convenience init(
        connectingTo request: URLRequest
    ) async throws {
        let api: RealtimeAPI
        api = try await RealtimeAPI.webRTC(connectingTo: request)
        self.init(client: api)
    }

    // MARK: - Connection Lifecycle

    /// Wait until the conversation is connected (polling).
    @MainActor
    public func waitForConnection() async {
        while !connected {
            try? await Task.sleep(for: .milliseconds(300))
        }
    }

    /// Run a closure once connected, then return its result.
    @MainActor
    public func whenConnected<E>(
        _ callback: @escaping @Sendable () async throws -> E
    ) async throws -> E {
        await waitForConnection()
        return try await callback()
    }

    // MARK: - Session Updates

    /// Update the session’s configuration. Fails if no session yet.
    public func updateSession(withChanges callback: (inout Session) -> Void) async throws {
        guard var s = await session else {
            throw ConversationError.sessionNotFound
        }
        callback(&s)
        try await setSession(s)
    }

    /// Replace the session entirely.
    public func setSession(_ session: Session) async throws {
        var copy = session
        // Clear ID so the server can decide
        copy.id = nil
        try await client.send(event: .updateSession(copy))
    }

    // MARK: - Sending

    /// Send a client event to the Realtime API (advanced usage).
    public func send(event: ClientEvent) async throws {
        try await client.send(event: event)
    }

    /// Send mic audio data as `appendInputAudioBuffer`.
    /// Pass `commit = true` to force the server to treat it as a complete user message.
    public func send(audioDelta audio: Data, commit: Bool = false) async throws {
        try await client.send(event: .appendInputAudioBuffer(encoding: audio))
        if commit {
            try await client.send(event: .commitInputAudioBuffer())
        }
    }

    /// Send a text-based message from user/system/assistant. Optionally create a response.
    public func send(
        from role: Item.ItemRole,
        text: String,
        response: Response.Config? = nil
    ) async throws {
        // If the assistant is currently speaking, interrupt
        if await handlingVoice {
            await interruptSpeech()
        }
        // Create a conversation item
        let newItem = Item(message: .init(
            id: String(randomLength: 32),
            from: role,
            content: [.input_text(text)]
        ))
        try await send(event: .createConversationItem(newItem))
        // Optionally request a response from the server
        if let response = response {
            try await send(event: .createResponse(response))
        } else {
            try await send(event: .createResponse()) // default
        }
    }

    /// Send the output of a function call to the conversation.
    public func send(result output: Item.FunctionCallOutput) async throws {
        try await send(event: .createConversationItem(.functionCallOutput(output)))
    }

    // MARK: - Voice Handling

    /// Start capturing the mic. Also sets up the audio engine for playback if not already done.
    @MainActor
    public func startListening() throws {
        guard !isListening else { return }
        if !handlingVoice {
            try startHandlingVoice()
        }
        let inputFormat = audioEngine.inputNode.outputFormat(forBus: 0)

        // Attach a tap for capturing the mic
        audioEngine.inputNode.installTap(
            onBus: 0,
            bufferSize: 4096,
            format: inputFormat
        ) { [weak self] buffer, _ in
            self?.processAudioBufferFromUser(buffer: buffer)
        }
        isListening = true
    }

    /// Stop capturing mic audio (does not stop playing assistant).
    @MainActor
    public func stopListening() {
        guard isListening else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        isListening = false
    }

    /// Set up for playing audio responses and (optionally) capturing mic if the user calls `startListening`.
    @MainActor
    public func startHandlingVoice() throws {
        guard !handlingVoice else { return }

        #if os(iOS)
        // For iOS, typical approach:
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetooth])
        // If you’d like to try forcing 24 kHz (no guarantee):
        // try audioSession.setPreferredSampleRate(24000)
        try audioSession.setActive(true)

        // If you want Apple’s built-in echo cancellation/noise suppression:
        // BUT that frequently enforces a different sample rate (16 kHz).
        // try audioEngine.inputNode.setVoiceProcessingEnabled(true)
        #endif

        // Build a converter from the device’s mic format → 24 kHz PCM16
        let micFormat = audioEngine.inputNode.outputFormat(forBus: 0)
        guard let inConverter = AVAudioConverter(from: micFormat, to: desiredFormat) else {
            throw ConversationError.converterInitializationFailed
        }
        userConverter.set(inConverter)

        // Connect the player node to the main mixer with no forced format,
        // letting iOS pick a valid sample rate for playback.
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)

        // Start the engine
        audioEngine.prepare()
        try audioEngine.start()

        handlingVoice = true
    }

    /// Stop both capturing mic audio and playing model responses.
    @MainActor
    public func stopHandlingVoice() {
        guard handlingVoice else { return }
        
        // Stop and remove audio engine nodes
        audioEngine.stop()
        if playerNode.engine != nil {
            audioEngine.disconnectNodeInput(playerNode)
            audioEngine.disconnectNodeOutput(playerNode)
            audioEngine.detach(playerNode)
        }
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
        
        isListening = false
        handlingVoice = false
    }

    /// Interrupt any assistant speech by sending a truncate event to the server.
    @MainActor
    public func interruptSpeech() {
//        print("interruptSpeech called")
        if isPlaying,
           let nodeTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: nodeTime),
           let itemID = queuedSamples.first
        {
            let audioTimeMs = Int((Double(playerTime.sampleTime) / playerTime.sampleRate) * 1000)
            Task {
                do {
                    try await client.send(event: .truncateConversationItem(
                        forItem: itemID,
                        atAudioMs: audioTimeMs
                    ))
                } catch {
                    print("Failed to send truncate event: \(error)")
                }
            }
        }
        playerNode.stop()
        queuedSamples.clear()
        Task { @MainActor in
            // Update isPlaying
            self.isPlaying = !self.queuedSamples.isEmpty
        }
    }

    // MARK: - Handling Server Events

    @MainActor
    private func handleEvent(_ event: ServerEvent) {
        switch event {
        case let .error(e):
            errorStream.yield(e.error)

        case let .sessionCreated(ev):
            connected = true
            session = ev.session

        case let .sessionUpdated(ev):
            session = ev.session

        case let .conversationCreated(ev):
            id = ev.conversation.id

        case let .conversationItemCreated(ev):
            entries.append(ev.item)
            if case let .message(msg) = ev.item {
                // Track if this is an audio message that needs transcription
                for content in msg.content {
                    if case .input_audio = content {
//                        print("Added pending transcription for message: \(msg.id)")
                    }
                }
            }

        case let .conversationItemInputAudioTranscriptionCompleted(ev):
            updateMessageEvent(ev.itemId) { msg in
                guard case let .input_audio(audio) = msg.content[ev.contentIndex] else { return }
                msg.content[ev.contentIndex] = .input_audio(.init(
                    audio: audio.audio,
                    transcript: ev.transcript
                ))
            }


        case let .conversationItemDeleted(ev):
            entries.removeAll { $0.id == ev.itemId }


        case let .conversationItemInputAudioTranscriptionFailed(ev):
            errorStream.yield(ev.error)

        case let .responseContentPartAdded(ev):
            updateMessageEvent(ev.itemId) { msg in
                msg.content.insert(.init(from: ev.part), at: ev.contentIndex)
            }

        case let .responseContentPartDone(ev):
            updateMessageEvent(ev.itemId) { msg in
                msg.content[ev.contentIndex] = .init(from: ev.part)
            }

        case let .responseTextDelta(ev):
            updateMessageEvent(ev.itemId) { msg in
                if case let .text(cur) = msg.content[ev.contentIndex] {
                    msg.content[ev.contentIndex] = .text(cur + ev.delta)
                }
            }

        case let .responseTextDone(ev):
            updateMessageEvent(ev.itemId) { msg in
                msg.content[ev.contentIndex] = .text(ev.text)
            }

        case let .responseAudioTranscriptDelta(ev):
            updateMessageEvent(ev.itemId) { msg in
                if case let .audio(a) = msg.content[ev.contentIndex] {
                    msg.content[ev.contentIndex] = .audio(.init(
                        audio: a.audio,
                        transcript: (a.transcript ?? "") + ev.delta
                    ))
                }
            }

        case let .responseAudioTranscriptDone(ev):
            updateMessageEvent(ev.itemId) { msg in
                if case let .audio(a) = msg.content[ev.contentIndex] {
                    msg.content[ev.contentIndex] = .audio(.init(
                        audio: a.audio,
                        transcript: ev.transcript
                    ))
                }
            }

        case let .responseAudioDelta(ev):
            // The inbound audio is 24 kHz PCM16, so queue for playback and store it
            updateMessageEvent(ev.itemId) { msg in
                if case let .audio(a) = msg.content[ev.contentIndex] {
                    if handlingVoice {
                        queueAudioSample(ev)
                    }
                    msg.content[ev.contentIndex] = .audio(.init(
                        audio: a.audio + ev.delta,
                        transcript: a.transcript
                    ))
                }
            }

        case let .responseFunctionCallArgumentsDelta(ev):
            updateFunctionCallEvent(ev.itemId) { fc in
                fc.arguments.append(ev.delta)
            }

        case let .responseFunctionCallArgumentsDone(ev):
            updateFunctionCallEvent(ev.itemId) { fc in
                fc.arguments = ev.arguments
            }

        case .inputAudioBufferSpeechStarted:
            isUserSpeaking = true
            // If we are playing audio right now, interrupt
            if handlingVoice { interruptSpeech() }

        case .inputAudioBufferSpeechStopped:
            isUserSpeaking = false

        case let .responseOutputItemDone(ev):
            // The final item might differ from partial updates
            updateOutputItemDone(ev.item)

        default:
            break
        }
    }

    @MainActor
    private func updateMessageEvent(_ itemId: String, update: (inout Item.Message) -> Void) {
        guard let idx = entries.firstIndex(where: { $0.id == itemId }),
              case var .message(msg) = entries[idx]
        else {
            return
        }
        update(&msg)
        entries[idx] = .message(msg)
    }

    @MainActor
    private func updateFunctionCallEvent(_ itemId: String, update: (inout Item.FunctionCall) -> Void) {
        guard let idx = entries.firstIndex(where: { $0.id == itemId }),
              case var .functionCall(fc) = entries[idx]
        else {
            return
        }
        update(&fc)
        entries[idx] = .functionCall(fc)
    }

    @MainActor
    private func updateOutputItemDone(_ newItem: Item) {
        // For example, if it's a message that changed status
        guard let idx = entries.firstIndex(where: { $0.id == newItem.id }) else { return }
        entries[idx] = newItem
    }

    // MARK: - Audio Playback

    /// Queue an audio buffer for playback. We get `delta` as 24 kHz PCM16 (base64) from the server.
    private func queueAudioSample(_ ev: ServerEvent.ResponseAudioDeltaEvent) {
        guard let rawBuffer = AVAudioPCMBuffer.fromData(ev.delta, format: desiredFormat) else {
            print("Failed to create PCM buffer from server data.")
            return
        }
        
        // Use local reference to avoid capturing self
        let localPlayerNode = playerNode
        
        guard let conv = apiConverter.lazy({
            let outFormat = localPlayerNode.outputFormat(forBus: 0)
            return AVAudioConverter(from: desiredFormat, to: outFormat)
        }) else {
            print("Failed to create converter for playback.")
            return
        }
        
        let ratio = conv.outputFormat.sampleRate / desiredFormat.sampleRate
        let outCap = AVAudioFrameCount(Double(rawBuffer.frameLength) * ratio)

        guard let convertedBuffer = convertBuffer(
            buffer: rawBuffer,
            using: conv,
            capacity: outCap
        ) else {
            print("Audio converter returned nil.")
            return
        }

        // Store audioID locally
        let audioId = ev.itemId
        queuedSamples.push(audioId)
        
        Task { @MainActor [weak self] in
            self?.isPlaying = !(self?.queuedSamples.isEmpty ?? true)
        }

        localPlayerNode.scheduleBuffer(convertedBuffer, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            guard let self = self else { return }
            self.queuedSamples.popFirst()

            if self.queuedSamples.isEmpty {
                localPlayerNode.pause()
            }

            Task { @MainActor [weak self] in
                self?.isPlaying = !(self?.queuedSamples.isEmpty ?? true)
            }
        }
        localPlayerNode.play()
    }

    // MARK: - Audio Capture

    /// Convert device mic → 24 kHz PCM16, then send to server.
    private func processAudioBufferFromUser(buffer: AVAudioPCMBuffer) {
        guard let conv = userConverter.get() else {
            return
        }
        let ratio = desiredFormat.sampleRate / buffer.format.sampleRate
        let outCap = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

        guard let outBuffer = convertBuffer(buffer: buffer, using: conv, capacity: outCap) else {
            print("Mic conversion failed.")
            return
        }

        let mBuf = outBuffer.audioBufferList.pointee.mBuffers
        guard let baseAddr = mBuf.mData else { return }
        let dataCount = Int(mBuf.mDataByteSize)
        let rawData = Data(bytes: baseAddr, count: dataCount)

        Task {
            try? await send(audioDelta: rawData)
        }
    }

    // MARK: - Generic Conversion

    /// Utility for calling AVAudioConverter once per buffer.
    private func convertBuffer(
        buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter,
        capacity: AVAudioFrameCount
    ) -> AVAudioPCMBuffer? {
        if buffer.format == converter.outputFormat {
            // No conversion needed
            return buffer
        }
        guard let outBuf = AVAudioPCMBuffer(
            pcmFormat: converter.outputFormat,
            frameCapacity: capacity
        ) else {
            print("Failed to allocate out buffer.")
            return nil
        }

        var error: NSError?
        var doneInput = false
        let status = converter.convert(to: outBuf, error: &error) { _, outStatus in
            if doneInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            doneInput = true
            outStatus.pointee = .haveData
            return buffer
        }

        if status == .error || error != nil {
            print("Audio conversion error: \(error?.localizedDescription ?? "unknown")")
            return nil
        }
        return outBuf
    }
}

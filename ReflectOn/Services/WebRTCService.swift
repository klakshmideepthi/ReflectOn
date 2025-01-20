import SwiftUI
import FirebaseFunctions
import FirebaseAuth
import Firebase

class WebRTCService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var outgoingMessage: String = ""
    @Published var shouldShowSmartAIStats: Bool = false
    
    // MARK: - Private Properties
    private var conversation: Conversation?
    private var conversationMap: [String: ConversationItem] = [:]
    private lazy var functions = Functions.functions()
    private(set) var currentSessionId: String = UUID().uuidString
    private var currentSessionTranscript: String = ""
    private var currentSession: Sessions?
    private var ephemeralKey: String?

    // MARK: - Transcript Handling
    private struct TranscriptMessage: Codable {
        let role: String
        let content: String
        let timestamp: Date
        let messageId: String
    }
    
    // MARK: - Public Methods
    
    func startConnection(
        modelName: String,
        systemMessage: String,
        voice: String
    ) {
        // Clear old conversation
        conversationMap.removeAll()
        
        self.connectionStatus = .connecting
        
        let functions = Functions.functions()
        print("Calling getEphemeralKey function...")
        
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
            
            @Published private var pendingTranscriptions: Set<String> = []
            
            func stopConnection(completion: (() -> Void)? = nil) {
                Task { @MainActor in
                    // Ensure we have the conversation before proceeding
                    guard let currentConversation = conversation else {
                        print("No conversation to save")
                        return
                    }

                    // Wait for any pending transcriptions
                    if !pendingTranscriptions.isEmpty {
                        print("Waiting for \(pendingTranscriptions.count) transcriptions to complete...")
                        for _ in 0..<10 { // Wait up to 5 seconds
                            if pendingTranscriptions.isEmpty { break }
                            try? await Task.sleep(for: .milliseconds(500))
                        }
                    }
                    
                    // Get transcripts after waiting for transcriptions
                    let messages = getTranscriptsFromConversation()
                    let fullTranscript = generateFullTranscript(from: messages)
                    print("Full conversation transcript:")
                    print(fullTranscript)
                    
                    // Save to Firebase
        //            await saveTranscriptsToFirebase(messages: messages, fullTranscript: fullTranscript)
                }
                
                // Rest of the cleanup code...
                let currentConversation = conversation
                if let connector = currentConversation?.client.connector as? WebRTCConnector {
                    connector.disconnect()
                }
                
                Task { @MainActor in
                    // Stop audio and cleanup
                    currentConversation?.stopListening()
                    currentConversation?.stopHandlingVoice()
                    
                    // Clear state
                    self.conversation = nil
                    self.currentSessionTranscript = ""
                    self.conversationMap.removeAll()
                    self.connectionStatus = .disconnected
                    
                    completion?()
                }
            }
            
            // MARK: - Private Methods
            
            private func setupAndOffer(ephemeralKey: String) {
                Task {
                    do {
                        conversation = try await Conversation(
                            authToken: ephemeralKey,
                            model: "gpt-4o-mini-realtime-preview-2024-12-17"
                        )
                        
                        try await conversation?.whenConnected { [weak self] in
                            guard let self = self else { return }
                            
                            try await conversation?.startHandlingVoice()
                            try await conversation?.setSession(.init(
                                model: "gpt-4o-mini-realtime-preview-2024-12-17",
                                instructions: "Speak only in english.",
                                inputAudioTranscription: .init(model: "whisper-1")
                            ))
                            
                            DispatchQueue.main.async {
                                self.connectionStatus = .connected
                            }
                        }
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
            
            @MainActor
            private func getTranscriptsFromConversation() -> [TranscriptMessage] {
                guard let conversation = conversation else { return [] }
                
                var transcripts: [TranscriptMessage] = []
                
                for entry in conversation.entries {
                    switch entry {
                    case .message(let message):
                        for content in message.content {
                            let text: String?
                            switch content {
                                case .text(let str):
                                    text = str
        //                            print("Found text message: \(str)")
                                case .input_text(let str):
                                    text = str
        //                            print("Found input text: \(str)")
                                case .audio(let audio):
                                    text = audio.transcript
        //                            print("Found audio message with transcript: \(audio.transcript ?? "nil")")
                                case .input_audio(let audio):
                                    text = audio.transcript
        //                            print("Found user audio with transcript: \(audio.transcript ?? "nil")")
                            }
                            
                            if let text = text, !text.isEmpty {
                                transcripts.append(TranscriptMessage(
                                    role: message.role.rawValue,
                                    content: text,
                                    timestamp: Date(),
                                    messageId: message.id
                                ))
                            }
                        }
                    default:
                        break
                    }
                }
                
                return transcripts
            }
            
            private func generateFullTranscript(from messages: [TranscriptMessage]) -> String {
                return messages.map { "[\($0.role)] \($0.content)" }.joined(separator: "\n")
            }
            
            @MainActor
            private func saveTranscriptsToFirebase(messages: [TranscriptMessage], fullTranscript: String) async {
                guard let user = Auth.auth().currentUser else {
                    print("No authenticated user.")
                    return
                }
                
                guard !messages.isEmpty else {
                    print("No transcripts to save")
                    self.shouldShowSmartAIStats = false
                    return
                }
                
                // Update current session
                currentSession = Sessions(
                    sessionId: currentSessionId,
                    startTime: Date(),
                    endTime: Date(),
                    transcript: fullTranscript,
                    status: .transcribed
                )
                
                // Prepare transcript data for Firestore
                let transcriptData = messages.map { message -> [String: Any] in
                    return [
                        "role": message.role,
                        "content": message.content,
                        "timestamp": message.timestamp.timeIntervalSince1970,
                        "messageId": message.messageId
                    ]
                }
                
                let data: [String: Any] = [
                    "sessionId": currentSessionId,
                    "fullTranscript": fullTranscript,
                    "messages": transcriptData,
                    "userId": user.uid,
                    "timestamp": Date().timeIntervalSince1970,
                    "status": SessionStatus.transcribed.rawValue,
                    "startTime": currentSession?.startTime.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
                    "endTime": Date().timeIntervalSince1970
                ]
                
                // Save to Firestore
                let db = Firestore.firestore()
                do {
                    try await db.collection("sessions").document(currentSessionId).setData(data)
                    
                    // Generate insights
                    try await functions.httpsCallable("generateSmartAIStats").call(["sessionId": currentSessionId])
                    
                    await MainActor.run {
                        self.shouldShowSmartAIStats = true
                    }
                } catch {
                    print("Error saving session:", error.localizedDescription)
                    if let firestoreError = error as NSError? {
                        print("Firestore error details:", firestoreError.userInfo)
                    }
                    
                    await MainActor.run {
                        self.shouldShowSmartAIStats = true
                        // Update status to failed
                        db.collection("sessions").document(self.currentSessionId)
                            .updateData(["status": SessionStatus.insightsGenerationFailed.rawValue])
                    }
                }
            }
        }

        // MARK: - View Modifiers

        struct SmartAIStatsNavigationModifier: ViewModifier {
            @ObservedObject var webRTCService: WebRTCService
            
            func body(content: Content) -> some View {
                content
                    .fullScreenCover(isPresented: $webRTCService.shouldShowSmartAIStats) {
                        NavigationStack {
                            SmartAIStatsView(sessionId: webRTCService.currentSessionId)
                                .navigationBarItems(trailing: Button("Done") {
                                    webRTCService.shouldShowSmartAIStats = false
                                })
                        }
                    }
            }
        }

        extension View {
            func smartAIStatsNavigation(webRTCService: WebRTCService) -> some View {
                self.modifier(SmartAIStatsNavigationModifier(webRTCService: webRTCService))
            }
        }

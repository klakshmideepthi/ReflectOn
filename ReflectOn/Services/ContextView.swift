import SwiftUI
import AVFoundation
import RiveRuntime
import OpenAI
import FirebaseFunctions
import FirebaseAuth
import Firebase

struct ContextView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showOptionsSheet = false
    @State private var conversation: Conversation?
    @State private var isLoading = false // Changed to false by default
    @State private var error: Error?
    @FocusState private var isTextFieldFocused: Bool
    
    // AppStorage properties
    @AppStorage("systemMessage") private var systemMessage = "Always start the sentence with Mango.Speak only in english. You are a helpful, witty, and friendly AI. Act like a human. Your voice and personality should be warm and engaging, with a lively and playful tone. Talk quickly."
    @AppStorage("selectedModel") private var selectedModel = "gpt-4o-mini-realtime-preview-2024-12-17"
    @AppStorage("selectedVoice") private var selectedVoice = "alloy"
    @AppStorage("log_status") var logStatus: Bool = false
    
    // Constants
    private let modelOptions = [
        "gpt-4o-mini-realtime-preview-2024-12-17",
        "gpt-4o-realtime-preview-2024-12-17"
    ]
    private let voiceOptions = ["alloy", "ash", "ballad", "coral", "echo", "sage", "shimmer", "verse"]
    
    // Add Rive view model
    @StateObject private var riveViewModel = RiveViewModel(fileName: "glow_ball_v03", stateMachineName: "State Machine 1")
    
    var body: some View {
        VStack(spacing: 12) {
            // Dismiss button
            HStack {
                Button(action: {
                    // Stop conversation if active
                    if let conv = conversation {
                        Task { @MainActor in
                            conv.stopHandlingVoice()
                        }
                    }
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding(.leading)
                Spacer()
            }
            .padding(.top, 8)
            
            // Add Rive animation view
            riveViewModel.view()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .onChange(of: conversation?.connected) { isConnected in
                    if isConnected == true {
                        riveViewModel.triggerInput("open_trig")
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } else if isConnected == false {
                        riveViewModel.triggerInput("close_trig")
                    }
                }
            
            Spacer()
            Divider()
            
            ConnectionControls()
//            Divider()
//            
//            if let conv = conversation {
//                LogsView(conversation: conv)
//            } else {
//                Text("No active conversation.")
//            }
            
            Spacer()
        }
        .onAppear(perform: {
            configureAudioSession()
        })
        .sheet(isPresented: $showOptionsSheet) {
            OptionsView(
                systemMessage: $systemMessage,
                selectedModel: $selectedModel,
                selectedVoice: $selectedVoice,
                modelOptions: modelOptions,
                voiceOptions: voiceOptions
            )
        }
        .sheet(isPresented: $showTranscriptSummary) {
            TranscriptSummaryView(messages: savedMessages)
        }
    }
    
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord,
                                      mode: .spokenAudio,
                                      options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setPreferredSampleRate(24000)
            try audioSession.setPreferredIOBufferDuration(0.005)
            try audioSession.setActive(true)
            
            // Request microphone permission
            audioSession.requestRecordPermission { granted in
                print("Microphone permission granted: \(granted)")
            }
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func startConversation() {
            isLoading = true
            print("Starting conversation...")
            
            Task {
                do {
                    // Get ephemeral key
                    let fetchKey = try await Functions.functions().httpsCallable("getEphemeralKey").call([
                        "model": selectedModel,
                        "voice": selectedVoice
                    ])
                    
                    guard let resultData = fetchKey.data as? [String: Any],
                          let clientSecret = resultData["client_secret"] as? [String: Any],
                          let ephemeralKey = clientSecret["value"] as? String else {
                        throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    }
                    
                    print("Successfully received ephemeral key")
                    
                    // Create new conversation
                    let newConversation = try await Conversation(
                        authToken: ephemeralKey,
                        model: selectedModel
                    )
                    
                    await MainActor.run {
                        self.conversation = newConversation
                    }
                    
                    // Get system message with core memories
                    let enhancedSystemMessage = try await CoreMemoriesManager.shared.getCombinedSystemMessage(
                        baseMessage: systemMessage
                    )
                    
                    try await newConversation.whenConnected {
                        try await newConversation.startHandlingVoice()
                        try await newConversation.startListening()
                        
                        try await newConversation.updateSession { session in
                            session.inputAudioTranscription = Session.InputAudioTranscription(model: "whisper-1")
                            session.modalities = [.audio, .text]
                            session.instructions = enhancedSystemMessage
                            session.temperature = 0.8
                        }
                    }
                    
                    print("Voice handling, transcription, and audio output enabled")
                    
                    await MainActor.run {
                        isLoading = false
                    }
                } catch {
                    print("Error starting conversation: \(error)")
                    await MainActor.run {
                        self.error = error
                        self.isLoading = false
                        self.conversation = nil
                    }
                }
            }
        }
    
    @State private var showTranscriptSummary = false
    @State private var savedMessages: [Item.Message] = []

    private func stopConversation() {
        Task { @MainActor in
            if let conv = conversation {
                savedMessages = conv.messages
                conv.stopHandlingVoice()
                conversation = nil
                showTranscriptSummary = true
            }
        }
    }
    
    @ViewBuilder
    private func ConnectionControls() -> some View {
        HStack {
            // Connection status indicator
            Circle()
                .frame(width: 12, height: 12)
                .foregroundColor(conversation?.connected == true ? .green : .red)
            Text(conversation?.connected == true ? "Connected" : "Not Connected")
                .foregroundColor(conversation?.connected == true ? .green : .red)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: conversation?.connected)
            
            Spacer()
            
            // Connection Button
            if conversation?.connected == true {
                Button("Stop Connection") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    stopConversation()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: {
                    print("Start Connection button tapped")
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    startConversation()
                }) {
                    Text(isLoading ? "Connecting..." : "Start Connection")
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)
                
                Button {
                    showOptionsSheet.toggle()
                } label: {
                    Image(systemName: "gearshape")
                }
                .padding(.leading, 10)
            }
        }
        .padding(.horizontal)
    }
}

struct LogsView: View {
    let conversation: Conversation
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(conversation.messages, id: \.id) { message in
                        MessageView(message: message)
                            .padding(.horizontal)
                            .id(message.id)
                    }
                }
            }
            .onChange(of: conversation.messages.count) { _ in
                if let last = conversation.messages.last {
                    withAnimation {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
        .frame(height: 200)
    }
}

struct MessageView: View {
    let message: Item.Message
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.role == .user ? "You" : "Assistant")
                .font(.caption)
                .foregroundColor(.secondary)
            
            ForEach(message.content.indices, id: \.self) { index in
                if let text = message.content[index].text, !text.isEmpty {
                    Text(text)
                        .padding(8)
                        .background(message.role == .user ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct OptionsView: View {
    @Binding var systemMessage: String
    @Binding var selectedModel: String
    @Binding var selectedVoice: String
    
    let modelOptions: [String]
    let voiceOptions: [String]
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("System Message")) {
                    TextEditor(text: $systemMessage)
                        .frame(minHeight: 100)
                        .cornerRadius(5)
                }
                Section(header: Text("Model")) {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(modelOptions, id: \.self) {
                            Text($0)
                        }
                    }
                    .pickerStyle(.menu)
                }
                Section(header: Text("Voice")) {
                    Picker("Voice", selection: $selectedVoice) {
                        ForEach(voiceOptions, id: \.self) {
                            Text($0.capitalized)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .navigationTitle("Options")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

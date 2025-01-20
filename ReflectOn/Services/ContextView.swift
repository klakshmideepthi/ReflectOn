import SwiftUI
import AVFoundation
import RiveRuntime

struct ContextView: View {
    @StateObject private var webrtcService = WebRTCService()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showOptionsSheet = false
    @FocusState private var isTextFieldFocused: Bool
    @AppStorage("log_status") var logStatus: Bool = false
    
    // AppStorage properties
    @AppStorage("systemMessage") private var systemMessage = "Speak only in english.You are a helpful, witty, and friendly AI. Act like a human. Your voice and personality should be warm and engaging, with a lively and playful tone. Talk quickly."
    @AppStorage("selectedModel") private var selectedModel = "gpt-4o-mini-realtime-preview-2024-12-17"
    @AppStorage("selectedVoice") private var selectedVoice = "alloy"
    
    // Constants
    private let modelOptions = [
        "gpt-4o-mini-realtime-preview-2024-12-17",
        "gpt-4o-realtime-preview-2024-12-17"
    ]
    private let voiceOptions = ["alloy", "ash", "ballad", "coral", "echo", "sage", "shimmer", "verse"]
    
    // Add Rive view model
    @StateObject private var riveViewModel = RiveViewModel(fileName: "glow_ball_v03",stateMachineName:"State Machine 1")
    
    var body: some View {
        VStack(spacing: 12) {
            // Dismiss button
            HStack {
                Button(action: {
                    // Stop WebRTC connection if active
                    if webrtcService.connectionStatus == .connected {
                        webrtcService.stopConnection()
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
                .allowsHitTesting(false) // Disables user interaction on the Rive view
                .onChange(of: webrtcService.connectionStatus) { newStatus in
                    print("Connection status changed to: \(newStatus)")
                    switch newStatus {
                    case .connected:
                        riveViewModel.triggerInput("open_trig")
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    case .connecting:
                        print("Connection in progress")
                        riveViewModel.triggerInput("bing_trig")
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    case .disconnected:
                        print("Connection disconnected")
                        riveViewModel.triggerInput("close_trig")
                    }
                }
            
            Spacer()
            
            ConnectionControls()
            
            Spacer()
            
        }
        .onAppear(perform: {
            requestMicrophonePermission()
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
        .smartAIStatsNavigation(webRTCService: webrtcService)
    }
    
    private func requestMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            print("Microphone permission granted: \(granted)")
        }
    }
    
    @ViewBuilder
    private func ConnectionControls() -> some View {
        HStack {
            // Connection status indicator
            Circle()
                .frame(width: 12, height: 12)
                .foregroundColor(webrtcService.connectionStatus.color)
            Text(webrtcService.connectionStatus.description)
                .foregroundColor(webrtcService.connectionStatus.color)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: webrtcService.connectionStatus)
                .onChange(of: webrtcService.connectionStatus) { _ in
                    switch webrtcService.connectionStatus {
                    case .connecting:
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    case .connected:
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    case .disconnected:
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }
            
            Spacer()
            
            // Connection Button
            if webrtcService.connectionStatus == .connected {
                Button("Stop Connection") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    webrtcService.stopConnection()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Start Connection") {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    webrtcService.connectionStatus = .connecting
                    webrtcService.startConnection(
                        modelName: selectedModel,
                        systemMessage: systemMessage,
                        voice: selectedVoice
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(webrtcService.connectionStatus == .connecting)
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
    
    
    // MARK: - Message Row
    @ViewBuilder
    private func MessageRow(msg: ConversationItem) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: msg.roleSymbol)
                .foregroundColor(msg.roleColor)
                .padding(.top, 4)
            Text(msg.text.trimmingCharacters(in: .whitespacesAndNewlines))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.1), value: msg.text)
        }
        .contextMenu {
            Button("Copy") {
                UIPasteboard.general.string = msg.text
            }
        }
        .padding(.bottom, msg.role == "assistant" ? 24 : 8)
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

// MARK: - Models and Enums

struct ConversationItem: Identifiable {
    let id: String        // item_id from the JSON
    let role: String       // "user" / "assistant"
    var text: String       // transcript
    
    var roleSymbol: String {
        role.lowercased() == "user" ? "person.fill" : "sparkles"
    }
    
    var roleColor: Color {
        role.lowercased() == "user" ? .blue : .purple
    }
}

enum ConnectionStatus: String {
    case connected
    case connecting
    case disconnected
    
    var color: Color {
        switch self {
        case .connected:
            return .green
        case .connecting:
            return .yellow
        case .disconnected:
            return .red
        }
    }
    
    var description: String {
        switch self {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Not Connected"
        }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContextView()
    }
}

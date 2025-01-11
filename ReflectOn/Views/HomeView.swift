import SwiftUI

struct HomeView: View {
    @State private var showSettings = false
    @State private var showReflectionSession = false
    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var webRTCService = WebRTCService()
    @AppStorage("systemMessage") private var systemMessage = "Speak only in english.You are a helpful, witty, and friendly AI. Act like a human. Your voice and personality should be warm and engaging, with a lively and playful tone. Talk quickly."
    @AppStorage("selectedModel") private var selectedModel = "gpt-4o-mini-realtime-preview-2024-12-17"
    @AppStorage("selectedVoice") private var selectedVoice = "alloy"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                Text("Welcome to ReflectOn")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                Text("Your daily reflection companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Main content
                VStack(spacing: 32) {
                    Button(action: {
                        // Generate key before showing reflection session
                        webRTCService.prepareConnection(
                            modelName: selectedModel,
                            systemMessage: systemMessage,
                            voice: selectedVoice
                        )
                        showReflectionSession = true
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40))
                            Text("Start Reflection")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    
                    // Stats preview
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Progress")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        HStack {
                            StatCard(title: "Sessions", value: "12")
                            StatCard(title: "Streak", value: "5")
                            StatCard(title: "Minutes", value: "120")
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
                .padding()
                
                Spacer()
            }
            .navigationBarItems(trailing: Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gear")
                    .imageScale(.large)
            })
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showReflectionSession) {
                ContextView(webrtcService: webRTCService)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 

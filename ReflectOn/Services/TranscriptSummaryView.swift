import SwiftUI
import FirebaseFunctions
import FirebaseAuth
import OpenAI

struct TranscriptSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let messages: [Item.Message]
    @State private var isSaving = false
    @State private var error: Error?
    @State private var showError = false
    @State private var showSmartAIStats = false
    @State private var savedSessionId = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if isSaving {
                    ProgressView("Saving session...")
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages, id: \.id) { message in
                                MessageSummaryView(message: message)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Session Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveSession()
                        }
                    }
                    .disabled(isSaving)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(error?.localizedDescription ?? "An unknown error occurred")
        }
        .fullScreenCover(isPresented: $showSmartAIStats) {
            NavigationView {
                SmartAIStatsView(sessionId: savedSessionId)
            }
        }
    }
    
    private func saveSession() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
            showError = true
            return
        }
        
        isSaving = true
        
        do {
            // Create session ID
            savedSessionId = UUID().uuidString
            
            // Combine all transcripts into one string
            let fullTranscript = messages.map { message in
                let role = message.role == .user ? "User" : "Assistant"
                return message.content.compactMap { $0.text }.map { "\(role): \($0)" }.joined(separator: "\n")
            }.joined(separator: "\n\n")
            
            // First, try to save the transcript
            try await Functions.functions().httpsCallable("transcribeAudio").call([
                "sessionId": savedSessionId,
                "transcript": fullTranscript,
                "userId": userId,
                "timestamp": Date().timeIntervalSince1970 * 1000 // Convert to milliseconds
            ])
            
            // Update core memories
            try await CoreMemoriesManager.shared.updateCoreMemories(
                withTranscript: fullTranscript
            )
            
            // If all operations succeed, show SmartAIStats
            await MainActor.run {
                isSaving = false
                showSmartAIStats = true
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                self.showError = true
                self.isSaving = false
            }
            
            // Log the error for debugging
            print("Error saving session: \(error.localizedDescription)")
        }
    }
}

struct MessageSummaryView: View {
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

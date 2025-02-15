import SwiftUI
import FirebaseFunctions
import FirebaseAuth

struct FeedbackView: View {
    let sessionId: String
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToHome = false
    
    @State private var rating: String = "thumbs_up"
    @State private var comment: String = ""
    @State private var isSubmitting = false
    @State private var error: Error?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("How was your session?")) {
                    Picker("Rating", selection: $rating) {
                        VStack {
                            Image(systemName: "hand.thumbsup.fill")
                            Text("Helpful")
                        }
                        .tag("thumbs_up")
                           
                        VStack {
                            Image(systemName: "hand.thumbsdown.fill")
                            Text("Not Helpful")
                        }
                        .tag("thumbs_down")
                    }
                    .pickerStyle(.segmented)
                }
                
                if rating == "thumbs_down" {
                    Section(header: Text("What could be improved?")) {
                        TextEditor(text: $comment)
                            .frame(height: 100)
                    }
                }
                
                Section {
                    Button(action: submitFeedback) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Submit Feedback")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("Session Feedback")
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error?.localizedDescription ?? "Unknown error occurred")
            }
            .fullScreenCover(isPresented: $navigateToHome) {
                HomeView()
            }
        }
    }
    
    private func submitFeedback() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        isSubmitting = true
        
        let feedbackData: [String: Any] = [
            "sessionId": sessionId,
            "rating": rating,
            "comment": rating == "thumbs_down" ? comment : "",
        ]
        
        Functions.functions().httpsCallable("saveFeedback")
            .call(feedbackData) { result, error in
                isSubmitting = false
                
                if let error = error {
                    self.error = error
                    showError = true
                } else {
                    // Set navigateToHome to true on successful submission
                    navigateToHome = true
                }
            }
    }
}

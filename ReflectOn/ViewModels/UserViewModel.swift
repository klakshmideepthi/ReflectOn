import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    
    func fetchUserData() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        error = nil

        do {
            let document = try await fetchDocument(withId: userId)
            
            // Now you're back on the main actor, so you can safely update UI-related properties.
            // For example:
            await MainActor.run {
                isLoading = false
                let data = document.data() ?? [:]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm"
                
                self.user = User(
                    userId: document.documentID,
                    email: data["email"] as? String ?? "",
                    focusAreas: data["focusAreas"] as? [String] ?? [],
                    age: data["age"] as? Int ?? 0,
                    gender: data["gender"] as? String ?? "",
                    reminderTime: dateFormatter.date(from: data["reminderTime"] as? String ?? "00:00") ?? Date(),
                    fcmToken: data["fcmToken"] as? String ?? "",
                    subscriptionStatus: data["subscriptionStatus"] as? String ?? "free",
                    onboardingComplete: data["onboardingComplete"] as? Bool ?? false
                )
            }
        } catch {
            await MainActor.run {
                isLoading = false
                self.error = error
            }
        }
    }

    private func fetchDocument(withId userId: String) async throws -> DocumentSnapshot {
        // We'll use a continuation here
        try await withCheckedThrowingContinuation { continuation in
            db.collection("users").document(userId).getDocument { document, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let document = document {
                    continuation.resume(returning: document)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Document not found"]
                    ))
                }
            }
        }
    }
    
    func updateUserData(field: String, value: Any) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        
        db.collection("users").document(userId).updateData([
            field: value
        ]) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.error = error
                } else {
                    Task {
                        await self?.fetchUserData()
                    }
                }
            }
        }
    }
}

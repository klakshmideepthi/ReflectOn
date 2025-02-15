import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserViewModel: ObservableObject {
    @Published var currentUser: User?
    private var db = Firestore.firestore()
    
    /// Loads user data from Firestore for a given userId.
    func loadUserData(userId: String) async throws {
        let doc = try await db.collection("users").document(userId).getDocument()
        if let data = doc.data() {
            let user = User(
                userId: data["userId"] as? String ?? "",
                email: data["email"] as? String ?? "",
                focusAreas: data["focusAreas"] as? [String] ?? [],
                age: data["age"] as? Int ?? 0,
                gender: data["gender"] as? String ?? "",
                reminderTime: (data["reminderTime"] as? Timestamp)?.dateValue() ?? Date(),
                fcmToken: data["fcmToken"] as? String ?? "",
                subscriptionStatus: data["subscriptionStatus"] as? String ?? "free",
                onboardingComplete: data["onboardingComplete"] as? Bool ?? false,
                coreMemories: data["coreMemories"] as? [String] ?? []
            )
            DispatchQueue.main.async {
                self.currentUser = user
            }
        }
    }
    
    /// Updates the user's focus areas in Firestore.
    func updateFocusAreas(_ focusAreas: [String]) async throws {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        try await db.collection("users").document(userId).updateData([
            "focusAreas": focusAreas
        ])
    }
    
    // Additional methods to update other user data as needed...
}

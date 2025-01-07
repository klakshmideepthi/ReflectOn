import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: Error?
    
    private let db = Firestore.firestore()
    
    func fetchUserData() {
        if let currentUser = Auth.auth().currentUser {
            print("Debug - Current User Info:")
            print("User ID: \(currentUser.uid)")
            print("Email: \(currentUser.email ?? "No email")")
            print("Is Email Verified: \(currentUser.isEmailVerified)")
            print("Provider ID: \(currentUser.providerData.map { $0.providerID })")
        } else {
            print("Debug - No authenticated user found")
        }
        
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("Debug - Failed to get userId")
            return 
        }
        print("Debug - Using userId: \(userId)")
        isLoading = true
        
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Debug - Firestore Error: \(error.localizedDescription)")
                    self?.error = error
                    return
                }
                
                if let document = document {
                    print("Debug - Document exists: \(document.exists)")
                    if document.exists {
                        print("Debug - Document data: \(document.data() ?? [:])")
                    }
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    print("#")
                    self?.error = NSError(domain: "", code: -1,
                                        userInfo: [NSLocalizedDescriptionKey: "User data not found"])
                    return
                }
                
                do {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "HH:mm"
                    
                    self?.user = User(
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
                    self?.fetchUserData() // Refresh user data after update
                }
            }
        }
    }
} 

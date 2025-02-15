import Foundation
import FirebaseAuth
import FirebaseFunctions

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: Int = 1
    @Published var completed: Bool = false
    @Published var selectedFocusAreas: [String] = []
    @Published var age: Int = 0
    @Published var gender: String = ""
    @Published var baselineAnswers: [String: String] = [:]
    @Published var reminderTime: Date = Date()
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var validationError: String?
    
    private let functions = Functions.functions()
    
    func goToNextStep() {
        currentStep += 1
    }
    
    func goToPreviousStep() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    func storeOnboardingDataToFirestore() async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "OnboardingError",
                         code: 0,
                         userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Convert Date to ISO8601 string format
        let dateFormatter = ISO8601DateFormatter()
        let reminderTimeString = dateFormatter.string(from: reminderTime)
        
        let userData: [String: Any] = [
            "selectedFocusAreas": selectedFocusAreas,
            "age": age,
            "gender": gender,
            "baselineAnswers": baselineAnswers,
            "reminderTime": reminderTimeString
        ]
        
        
        print("User Data", userData)
        
        return try await withCheckedThrowingContinuation { continuation in
            functions.httpsCallable("storeOnboardingData").call(userData) { [weak self] result, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        print("Firebase error:", error)
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let data = result?.data as? [String: Any],
                          let success = data["success"] as? Bool else {
                        let error = NSError(domain: "",
                                          code: -1,
                                          userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    self.completed = success
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

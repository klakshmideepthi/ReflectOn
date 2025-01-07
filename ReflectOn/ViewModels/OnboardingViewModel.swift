import Foundation
import SwiftUI
import FirebaseFunctions

class OnboardingViewModel: ObservableObject {
    @Published var selectedFocusAreas: Set<String> = []
    @Published var age: Int = 0
    @Published var gender: String = ""
    @Published var reminderTime: Date = Date()
    @Published var isLoading: Bool = false
    @Published var error: Error?
    @Published var validationError: String?
    
    private let functions = Functions.functions()
    
    func canProceedFromCurrentStep(_ step: Int) -> Bool {
        switch step {
        case 1: // Focus Areas
            if selectedFocusAreas.count != 2 {
                validationError = "Please select exactly 2 focus areas"
                return false
            }
        case 2: // Age
            if age <= 0 || age > 120 {
                validationError = "Please enter a valid age"
                return false
            }
        case 3: // Gender
            if gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationError = "Please enter your gender"
                return false
            }
        default:
            validationError = nil
            return true
        }
        validationError = nil
        return true
    }
    
    func saveUserData(completion: @escaping (Bool) -> Void) {
        isLoading = true
        error = nil
        
        // Format the date to string (HH:mm format)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let reminderTimeString = dateFormatter.string(from: reminderTime)
        
        // Prepare data for the Cloud Function
        let data: [String: Any] = [
            "selectedFocusAreas": Array(selectedFocusAreas),
            "age": age,
            "gender": gender,
            "reminderTime": reminderTimeString,
            "baselineAnswers": [:] // Empty for now, will be populated when we implement baseline questions
        ]
        
        // Call the Cloud Function
        functions.httpsCallable("storeOnboardingData").call(data) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                print("$1")
                
                if let error = error {
                    self?.error = error
                    completion(false)
                    return
                }
                print("$2")
                
                guard let data = result?.data as? [String: Any],
                      let success = data["success"] as? Bool else {
                    self?.error = NSError(domain: "", code: -1, 
                                        userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
                    print("$1")
                    completion(false)
                    return
                }
                
                completion(success)
            }
        }
    }
} 

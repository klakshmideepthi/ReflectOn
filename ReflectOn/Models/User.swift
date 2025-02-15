import Foundation

struct User {
    let userId: String
    var email: String
    var focusAreas: [String]
    var age: Int
    var gender: String
    var reminderTime: Date
    var fcmToken: String
    var subscriptionStatus: String
    var onboardingComplete: Bool
    var coreMemories: [String]
}

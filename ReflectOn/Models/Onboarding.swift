import Foundation

struct Onboarding {
    let userId: String // The anonymous user's unique ID
    var appVersion: String // The version of the app when the user started onboarding
    var timestamp: Date // Timestamp when the user started onboarding
    var step: Int // The current step in the onboarding process the user has reached (1-17)
    var completed: Bool // Indicates whether the user has completed the entire onboarding process
} 

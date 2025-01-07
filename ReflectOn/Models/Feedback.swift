import Foundation

struct Feedback {
    let feedbackId: String // Auto-generated unique ID
    var rating: String // "thumbs_up" or "thumbs_down"
    var comment: String? // User's comment if rating is "thumbs_down" (optional)
    var timestamp: Date // Server timestamp
} 
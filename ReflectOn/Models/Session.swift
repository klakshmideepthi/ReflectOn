import Foundation

enum SessionStatus: String {
    case initializing = "initializing"
    case inProgress = "in progress"
    case completed = "completed"
    case transcribed = "transcribed"
    case insightsGenerated = "insights_generated"
    case evaluated = "evaluated"
    case cancelled = "cancelled"
    case transcriptionFailed = "transcription_failed"
    case insightsGenerationFailed = "insights_generation_failed"
    case evaluationFailed = "evaluation_failed"
}

struct Insights {
    var focusArea1: FocusAreaInsight
    var focusArea2: FocusAreaInsight
    var emotions: [String] // List of dominant emotions
    var keyThemes: [String] // Key themes identified
    var actionableSteps: [String] // Actionable steps for the user
}

struct FocusAreaInsight {
    var name: String
    var paragraph: String // Explanation of how the session addressed this focus area
}

struct Evaluation {
    var clarityScore: Int
    var emotionalInsightScore: Int
    var actionabilityScore: Int
    var consistencyAndGrowthScore: Int
    var valuesAlignmentScore: Int
    var clarityFeedback: String
    var emotionalInsightFeedback: String
    var actionabilityFeedback: String
    var consistencyAndGrowthFeedback: String
    var valuesAlignmentFeedback: String
}

struct Session {
    let sessionId: String
    var startTime: Date
    var endTime: Date?
    var transcript: String?
    var status: SessionStatus
    var insights: Insights? // Optional insights object
    var evaluation: Evaluation? // Optional evaluation object
}

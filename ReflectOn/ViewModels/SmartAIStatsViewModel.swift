import Foundation
import FirebaseFirestore
import FirebaseFunctions

@MainActor
class SmartAIStatsViewModel: ObservableObject {
    @Published var insights: SmartAIStats?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var sessionStatus: SessionStatus = .initializing
    
    private let db = Firestore.firestore()
    
    struct SmartAIStats: Codable {
        struct FocusArea: Codable {
            let name: String
            let paragraph: String
        }
        
        let focus_area_1: FocusArea
        let focus_area_2: FocusArea
        let emotions: [String]
        let key_themes: [String]
        let actionable_steps: [String]
    }
    
    func generateInsights(sessionId: String) async throws {
        try await Functions.functions().httpsCallable("generateSmartAIStats").call([
            "sessionId": sessionId
        ])
    }
    
    func loadInsights(sessionId: String) async {
        isLoading = true
        
        do {
            // First generate the insights
            try await generateInsights(sessionId: sessionId)
            
            // Then start listening for updates
            db.collection("sessions").document(sessionId)
                .addSnapshotListener { [weak self] documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    guard let data = document.data() else {
                        print("Document data was empty")
                        return
                    }
                    
                    // Update session status
                    if let statusString = data["status"] as? String,
                       let status = SessionStatus(rawValue: statusString) {
                        self?.sessionStatus = status
                    }
                    
                    // If insights are available and status is completed, update the UI
                    if let insights = data["insights"] as? [String: Any],
                       self?.sessionStatus == .insightsGenerated {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: insights)
                            let decodedInsights = try JSONDecoder().decode(SmartAIStats.self, from: jsonData)
                            self?.insights = decodedInsights
                            self?.isLoading = false
                        } catch {
                            self?.error = error
                            self?.isLoading = false
                        }
                    }
                    
                    // Handle error state
                    if self?.sessionStatus == .insightsGenerationFailed {
                        self?.error = NSError(domain: "", code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Failed to generate insights"])
                        self?.isLoading = false
                    }
                }
        } catch {
            self.error = error
            self.isLoading = false
        }
    }
}

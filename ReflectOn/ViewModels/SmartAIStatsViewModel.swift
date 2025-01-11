import Foundation
import FirebaseFirestore

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
    
    func loadInsights(sessionId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Listen for real-time updates to the session
            db.collection("sessions").document(sessionId)
                .addSnapshotListener { [weak self] snapshot, error in
                    guard let self = self,
                          let data = snapshot?.data(),
                          error == nil else { return }
                    
                    // Update status
                    if let statusStr = data["status"] as? String,
                       let status = SessionStatus(rawValue: statusStr) {
                        self.sessionStatus = status
                    }
                    
                    // Update insights when available
                    if let insightsData = data["insights"] as? [String: Any] {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: insightsData)
                            self.insights = try JSONDecoder().decode(SmartAIStats.self, from: jsonData)
                        } catch {
                            self.error = error
                        }
                    }
                }
            
        } catch {
            self.error = error
        }
    }
} 

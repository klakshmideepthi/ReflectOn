import Foundation
import FirebaseFunctions
import FirebaseFirestore
import FirebaseAuth

class CoreMemoriesManager {
    static let shared = CoreMemoriesManager()
    private let db = Firestore.firestore()
    private let functions = Functions.functions()
    
    private init() {}
    
    // Fetch core memories for the current user
    func fetchCoreMemories() async throws -> [String] {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "CoreMemoriesManager", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        let docSnapshot = try await db.collection("users").document(userId).getDocument()
        guard let data = docSnapshot.data() else {
            throw NSError(domain: "CoreMemoriesManager", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "User document not found"
            ])
        }
        
        return data["coreMemories"] as? [String] ?? []
    }
    
    // Format core memories as part of system instructions
    func formatCoreMemoriesInstruction(_ memories: [String]) -> String {
        guard !memories.isEmpty else { return "" }
        
        return """
        Here are this person's core memories that provide context for their life and experiences:
        \(memories.enumerated().map { "Memory \($0 + 1): \($1)" }.joined(separator: "\n"))
        
        Please keep these memories in mind during our conversation and reference them when relevant.
        """
    }
    
    // Update core memories after a session
    func updateCoreMemories(withTranscript transcript: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "CoreMemoriesManager", code: 401, userInfo: [
                NSLocalizedDescriptionKey: "User not authenticated"
            ])
        }
        
        // Call the Firebase function to update core memories
        try await functions.httpsCallable("updateCoreMemories").call([
            "transcript": transcript
        ])
    }
    
    // Get combined system message with core memories
    func getCombinedSystemMessage(baseMessage: String) async throws -> String {
        let memories = try await fetchCoreMemories()
        let memoryInstructions = formatCoreMemoriesInstruction(memories)
        
        // Combine base message with core memories
        return [baseMessage, memoryInstructions]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }
}

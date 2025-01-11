import SwiftUI

struct SmartAIStatsView: View {
    let sessionId: String
    @StateObject private var viewModel = SmartAIStatsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            switch viewModel.sessionStatus {
            case .initializing:
                LoadingView(message: "Analyzing your session...")
            case .insightsGenerationFailed:
                ErrorView(message: "Failed to generate insights", error: viewModel.error) {
                    Task {
                        await viewModel.loadInsights(sessionId: sessionId)
                    }
                }
            case .insightsGenerated:
                insightsContent
            default:
                LoadingView(message: "Processing...")
            }
        }
        .navigationTitle("Session Insights")
        .task {
            await viewModel.loadInsights(sessionId: sessionId)
        }
    }
    
    private var insightsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let insights = viewModel.insights {
                    // Focus Areas Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Focus Areas")
                            .font(.headline)
                        
                        FocusAreaCard(
                            title: insights.focus_area_1.name,
                            content: insights.focus_area_1.paragraph
                        )
                        
                        FocusAreaCard(
                            title: insights.focus_area_2.name,
                            content: insights.focus_area_2.paragraph
                        )
                    }
                    .padding(.horizontal)
                    
                    // Emotions Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Emotional Landscape")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(insights.emotions, id: \.self) { emotion in
                                    EmotionCard(emotion: emotion)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Key Themes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Key Themes & Insights")
                            .font(.headline)
                        
                        ForEach(insights.key_themes, id: \.self) { theme in
                            ThemeCard(content: theme)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Actionable Steps Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Actionable Steps")
                            .font(.headline)
                        
                        ForEach(Array(insights.actionable_steps.enumerated()), id: \.element) { index, step in
                            ActionStepCard(number: index + 1, content: step)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

// Error View
struct ErrorView: View {
    let message: String
    let error: Error?
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text(message)
                .font(.headline)
            
            if let error = error {
                Text(error.localizedDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: retryAction) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
    }
}

// Supporting Views
struct FocusAreaCard: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(content)
                .font(.body)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct EmotionCard: View {
    let emotion: String
    
    var body: some View {
        Text(emotion)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(20)
    }
}

struct ThemeCard: View {
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "circle.fill")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 6)
            Text(content)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct ActionStepCard: View {
    let number: Int
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(content)
                .font(.body)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
} 
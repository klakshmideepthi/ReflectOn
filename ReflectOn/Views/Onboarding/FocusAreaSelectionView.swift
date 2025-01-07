import SwiftUI

struct FocusAreasSelectionView: View {
    @Binding var currentStep: Int
    @Binding var selectedAreas: Set<String>

    let focusAreas = [
        "Emotional Awareness", "Stress Reduction", "Personal Growth",
        "Strengths and Weaknesses", "Better Decision-Making", "Improved Relationships",
        "Positive Habits", "Gratitude", "Self-Compassion", "Mindfulness", "Goal Setting"
    ]

    var body: some View {
        VStack(spacing: 16) {
            Text("Select your focus areas")
                .font(.headline)
                .padding(.top)
            
            Text("Choose 2 areas to focus on")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("\(selectedAreas.count)/2 selected")
                .font(.caption)
                .foregroundColor(selectedAreas.count == 2 ? .green : .blue)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(focusAreas, id: \.self) { area in
                        HStack {
                            Text(area)
                                .foregroundColor(selectedAreas.count >= 2 && !selectedAreas.contains(area) ? .gray : .primary)
                            Spacer()
                            if selectedAreas.contains(area) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            } else if selectedAreas.count >= 2 {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    .frame(width: 22, height: 22)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedAreas.contains(area) {
                                selectedAreas.remove(area)
                            } else if selectedAreas.count < 2 {
                                selectedAreas.insert(area)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
} 

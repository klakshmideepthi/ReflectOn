import SwiftUI

struct FocusArea: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subAreas: [String]
    var isExpanded: Bool = false
    var selectedSubAreas: Set<String> = []
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FocusArea, rhs: FocusArea) -> Bool {
        lhs.id == rhs.id
    }
}

struct FocusAreaView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    @State private var expandedAreaId: UUID? = nil
    @State private var focusAreas: [FocusArea] = [
        FocusArea(title: "Emotional Awareness", subAreas: [
            "Understanding Emotions",
            "Emotional Regulation",
            "Self-Expression",
            "Empathy Development"
        ]),
        FocusArea(title: "Stress Reduction", subAreas: [
            "Mindfulness Practices",
            "Breathing Techniques",
            "Time Management",
            "Work-Life Balance"
        ]),
        FocusArea(title: "Personal Growth", subAreas: [
            "Goal Setting",
            "Self-Discovery",
            "Skill Development",
            "Learning From Experiences"
        ]),
        FocusArea(title: "Better Decision-Making", subAreas: [
            "Critical Thinking",
            "Problem Solving",
            "Risk Assessment",
            "Intuition Development"
        ]),
        FocusArea(title: "Improved Relationships", subAreas: [
            "Communication Skills",
            "Boundary Setting",
            "Conflict Resolution",
            "Building Trust"
        ]),
        FocusArea(title: "Positive Habits", subAreas: [
            "Habit Formation",
            "Daily Routines",
            "Healthy Lifestyle",
            "Productivity"
        ]),
        FocusArea(title: "Self-Compassion", subAreas: [
            "Self-Acceptance",
            "Inner Dialogue",
            "Self-Care Practices",
            "Resilience Building"
        ])
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Select Two Focus Areas")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(Color.theme.text.primary)
                .padding(.top, 20)
            
            Text("Choose the areas you want to focus on in your reflection journey")
                .font(.subheadline)
                .foregroundColor(Color.theme.text.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach($focusAreas) { $area in
                        FocusAreaCardView(
                            area: $area,
                            isSelected: onboardingVM.selectedFocusAreas.contains(area.title),
                            isExpanded: area.id == expandedAreaId,
                            onSelect: { handleAreaSelection(area: area) },
                            onToggleExpansion: { handleAreaExpansion(areaId: area.id) },
                            onSubAreaSelect: { subArea in
                                handleSubAreaSelection(areaId: area.id, subArea: subArea)
                            }
                        )
                    }
                }
                .padding()
            }
            
            VStack(spacing: 16) {
                Button(action: {
                    if onboardingVM.selectedFocusAreas.count == 2 {
                        onboardingVM.goToNextStep()
                    }
                }) {
                    Text(onboardingVM.selectedFocusAreas.count == 2 ? "Continue" : "Select \(2 - onboardingVM.selectedFocusAreas.count) more")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            onboardingVM.selectedFocusAreas.count == 2 ?
                            Color.theme.accent : Color.gray
                        )
                        .cornerRadius(10)
                }
                .disabled(onboardingVM.selectedFocusAreas.count != 2)
                
                Button("Back") {
                    onboardingVM.goToPreviousStep()
                }
                .font(.headline)
                .foregroundColor(Color.theme.text.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .background(Color.theme.background)
    }
    
    private func handleAreaSelection(area: FocusArea) {
        if onboardingVM.selectedFocusAreas.contains(area.title) {
            onboardingVM.selectedFocusAreas.removeAll(where: { $0 == area.title })
            
            // Reset the deselected area
            if let index = focusAreas.firstIndex(where: { $0.id == area.id }) {
                focusAreas[index].selectedSubAreas.removeAll()
            }
            // Close expansion when deselecting
            if expandedAreaId == area.id {
                expandedAreaId = nil
            }
        } else {
            if onboardingVM.selectedFocusAreas.count < 2 {
                onboardingVM.selectedFocusAreas.append(area.title)
            }
        }
    }
    
    private func handleAreaExpansion(areaId: UUID) {
        withAnimation(.easeInOut) {
            if expandedAreaId == areaId {
                expandedAreaId = nil
            } else {
                expandedAreaId = areaId
            }
        }
    }
    
    private func handleSubAreaSelection(areaId: UUID, subArea: String) {
        if let index = focusAreas.firstIndex(where: { $0.id == areaId }) {
            if focusAreas[index].selectedSubAreas.contains(subArea) {
                focusAreas[index].selectedSubAreas.remove(subArea)
            } else {
                focusAreas[index].selectedSubAreas.insert(subArea)
            }
        }
    }
}

struct FocusAreaCardView: View {
    @Binding var area: FocusArea
    let isSelected: Bool
    let isExpanded: Bool
    let onSelect: () -> Void
    let onToggleExpansion: () -> Void
    let onSubAreaSelect: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Main button with separated selection and expansion
            HStack {
                // Square checkbox for focus area
                Button(action: onSelect) {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .foregroundColor(isSelected ? Color.theme.accent : Color.gray)
                        .font(.system(size: 20))
                }
                .padding(.trailing, 8)
                
                Text(area.title)
                    .font(.headline)
                    .foregroundColor(Color.theme.text.primary)
                
                Spacer()
                
                Button(action: onToggleExpansion) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color.theme.text.primary)
                        .font(.system(size: 14, weight: .bold))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(area.subAreas, id: \.self) { subArea in
                        if isSelected { // Only show sub-area selection if focus area is selected
                            Button(action: {
                                onSubAreaSelect(subArea)
                            }) {
                                HStack {
                                    Image(systemName: area.selectedSubAreas.contains(subArea) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(Color.theme.accent)
                                    Text(subArea)
                                        .font(.subheadline)
                                        .foregroundColor(Color.theme.text.primary)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else {
                            // Show disabled state when focus area is not selected
                            HStack {
                                Image(systemName: "circle")
                                    .foregroundColor(Color.gray)
                                Text(subArea)
                                    .font(.subheadline)
                                    .foregroundColor(Color.gray)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
            }
        }
    }
}

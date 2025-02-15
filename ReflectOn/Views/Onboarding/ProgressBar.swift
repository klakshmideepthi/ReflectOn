import SwiftUI

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    private var progress: CGFloat {
        CGFloat(currentStep - 2) / CGFloat(totalSteps)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: 4)
                    .foregroundColor(.gray.opacity(0.3))
                
                Rectangle()
                    .frame(width: geometry.size.width * progress, height: 4)
                    .foregroundColor(Color.theme.accent)
                    .animation(.linear(duration: 0.3), value: progress)
            }
        }
        .frame(height: 4)
        .padding(.horizontal)
    }
}

// Extension to use in OnboardingViewModel
extension OnboardingViewModel {
    var totalSteps: Int { 8 } // Total number of onboarding steps
    
    var progress: CGFloat {
        CGFloat(currentStep) / CGFloat(totalSteps)
    }
}

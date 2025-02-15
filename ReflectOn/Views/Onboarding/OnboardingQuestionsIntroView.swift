import SwiftUI

struct OnboardingQuestionsIntroView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack {
                
                Spacer()
                
                // Main text
                Text("Answer a few questions\nto personalize your\nexperience")
                    .font(.system(size: 34))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    onboardingVM.goToNextStep()
                }) {
                    Text("TAP TO CONTINUE")
                        .font(.caption)
                        .foregroundColor(.mint)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    OnboardingQuestionsIntroView(onboardingVM: OnboardingViewModel())
}

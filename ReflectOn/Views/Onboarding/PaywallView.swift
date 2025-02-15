import SwiftUI

struct PaywallView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Upgrade to Premium")
                .font(.largeTitle)
            
            Text("Get unlimited access to advanced insights, daily reminders, and more.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Subscribe Now") {
                // Implement subscription logic (StoreKit, etc.)
                // On success or skip:
                onboardingVM.goToNextStep()
            }
            .buttonStyle(.borderedProminent)
            
            Button("Maybe Later") {
                onboardingVM.goToNextStep()
            }
            .padding(.top, 8)
            Spacer()
        }
        .padding()
    }
}

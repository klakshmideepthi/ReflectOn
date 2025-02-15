import SwiftUI

struct OnboardingView: View {
    @StateObject private var onboardingVM = OnboardingViewModel()
    
    var body: some View {
        NavigationStack {
            VStack {
                if onboardingVM.currentStep > 2 {
                    ProgressBar(currentStep: onboardingVM.currentStep, totalSteps: onboardingVM.totalSteps)
                }
                
                Spacer()
                
                switch onboardingVM.currentStep {
                case 1:
                    IntroductionView(onboardingVM: onboardingVM)
                case 2:
                    LoginOptionsView(onboardingVM: onboardingVM)
                case 3:
                    OnboardingQuestionsIntroView(onboardingVM: onboardingVM)
                case 4:
                    FocusAreaView(onboardingVM: onboardingVM)
                case 5:
                    AgeView(onboardingVM: onboardingVM)
                case 6:
                    GenderView(onboardingVM: onboardingVM)
                case 7:
                    // First baseline question
                    BaselineQuestionsView(onboardingVM: onboardingVM, questionSet: 1)
                case 8:
                    // Second baseline question
                    BaselineQuestionsView(onboardingVM: onboardingVM, questionSet: 2)
                case 9:
                    // Third baseline question
                    BaselineQuestionsView(onboardingVM: onboardingVM, questionSet: 3)
                case 10:
                    ReminderSetupView(onboardingVM: onboardingVM)
                case 11:
                    PaywallView(onboardingVM: onboardingVM)
                case 12:
                    LoginView(onboardingVM: onboardingVM)
                default:
                    Text("Onboarding Complete")
                        .onAppear {
                            // Possibly trigger a navigation to HomeView
                        }
                }
            }
            .padding()
            .navigationBarBackButtonHidden(true)
        }
    }
}

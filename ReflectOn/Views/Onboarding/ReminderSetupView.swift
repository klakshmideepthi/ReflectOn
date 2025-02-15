import SwiftUI

struct ReminderSetupView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Title
                Text("Let's Make Self-Reflection a Habit!")
                    .font(.system(size: 28))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Subtitle
                VStack(spacing: 8) {
                    Text("Choose a time for your daily self-reflection.")
                        .font(.system(size: 12))
                        .foregroundColor(.blue.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                    
                    Text("We'll remind you gently each day.")
                        .font(.system(size: 12))
                        .foregroundColor(.blue.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                }
                
                // Time Picker
                DatePicker("Reminder Time",
                          selection: $onboardingVM.reminderTime,
                          displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.wheel)
                    .frame(maxWidth: 300)
                    .padding(.vertical, 40)
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    onboardingVM.goToNextStep()
                }) {
                    Text("TAP TO CONTINUE")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.bottom, 40)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    ReminderSetupView(onboardingVM: OnboardingViewModel())
}

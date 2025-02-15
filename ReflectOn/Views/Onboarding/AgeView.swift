import SwiftUI

struct AgeView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    @State private var ageInput: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var showAgeWarning: Bool = false
    @State private var warningMessage: String = ""
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Progress bar at top
                Spacer()
                
                Text("How old are you?")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundColor(Color.theme.text.primary)
                
                Text("Your guidance will be tailored\nto your age group.")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(Color.theme.text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                TextField("age", text: $ageInput)
                    .font(.system(size: 48, weight: .light))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($isInputFocused)
                    .foregroundColor(Color.theme.accent)
                    .onChange(of: ageInput) { _ in
                        // Hide warning when user starts typing again
                        showAgeWarning = false
                    }
                
                // Age warning message
                if showAgeWarning {
                    Text(warningMessage)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.top, 8)
                        .transition(.opacity)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                Button(action: {
                    validateAndProceed()
                }) {
                    Text("Done")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.theme.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                isInputFocused = true
            }
        }
    }
    
    private func validateAndProceed() {
        guard !ageInput.isEmpty else {
            warningMessage = "Please enter your age"
            showAgeWarning = true
            return
        }
        
        guard let ageNumber = Int(ageInput) else {
            warningMessage = "Please enter a valid number"
            showAgeWarning = true
            return
        }
        
        if ageNumber < 18 {
            warningMessage = "You must be at least 18 years old to use this app"
            showAgeWarning = true
            return
        }
        
        if ageNumber > 100 {
            warningMessage = "Please enter a valid age"
            showAgeWarning = true
            return
        }
        
        // If all validations pass
        onboardingVM.age = ageNumber
        onboardingVM.goToNextStep()
    }
}

#Preview {
    AgeView(onboardingVM: OnboardingViewModel())
}

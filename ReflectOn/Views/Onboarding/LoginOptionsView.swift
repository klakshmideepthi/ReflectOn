import SwiftUI

struct LoginOptionsView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    @State private var showLogin = false
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack() {
                Spacer()
                
                // App Icon
                Circle()
                    .fill(Color(red: 0.8, green: 0.9, blue: 0.9))
                    .frame(width: 200, height: 200)
                    .overlay(
                        Image(systemName: "hare.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.blue)
                            .padding(30)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.blue, lineWidth: 3)
                    )
                Spacer()
                
                // App Title and Description
                VStack(spacing: 12) {
                    Text("Reflecton: Your companion")
                        .font(.title)
                        .foregroundColor(Color.theme.text.primary)
                    
                    Text("for meaningful self-reflection.")
                        .font(.title)
                        .foregroundColor(Color.theme.text.primary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        onboardingVM.goToNextStep()
                    }) {
                        Text("Get started for free")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal, 32)
                    
                    // Login Link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(Color.theme.text.secondary)
                        
                        Button(action: {
                            showLogin = true
                        }) {
                            Text("Log In")
                                .foregroundColor(.blue)
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(onboardingVM: onboardingVM)
        }
    }
}

import SwiftUI
import AuthenticationServices

/// A view that appears after the paywall. Allows the user to sign in with Apple or Google.
struct LoginView: View {
    
    @StateObject private var loginVM = LoginViewModel()
    
    /// Reference your Onboarding data if you want to store it after login
    @ObservedObject var onboardingVM: OnboardingViewModel
    
    /// Navigation
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToHome: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                Text("Sign In or Create an Account")
                    .font(.title)
                    .padding(.top, 40)
                
                // Sign in with Apple
                SignInWithAppleButton(.signIn, onRequest: { request in
                    loginVM.handleSignInWithAppleRequest(request)
                },
                onCompletion: { result in
                    Task {
                        await loginVM.signInWithApple(onboardingVM : onboardingVM,result: result)
                    }
                })
                .signInWithAppleButtonStyle(.black)
                .frame(height: 45)
                .cornerRadius(8)
                .padding(.horizontal, 50)
                
                // Sign in with Google
                Button {
                    Task {
                        await loginVM.signInWithGoogle(onboardingVM : onboardingVM)
                    }
                } label: {
                    HStack {
                        Image("googleLogo") // Provide a Google logo asset
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Sign in with Google")
                            .fontWeight(.semibold)
                    }
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 45)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal, 50)
                
                if let errorMessage = loginVM.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                // For demonstration: a skip button
                Button("Skip for Now") {
                    dismiss() // or navigate to Home
                }
                .padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $navigateToHome) {
                // Navigate to HomeView
                HomeView()
                    .navigationBarBackButtonHidden(true)
            }
            .onReceive(loginVM.$shouldNavigateToHome) { value in
                if value == true {
                    navigateToHome = true
                }
            }
        }
        .overlay(
            Group {
                if loginVM.isLoading {
                    ProgressView("Signing in...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.2)
                }
            }
        )
    }
}

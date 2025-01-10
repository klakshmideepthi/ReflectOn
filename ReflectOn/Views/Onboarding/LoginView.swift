import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import Firebase
import AuthenticationServices

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @State private var isLoggedIn = false
    @State private var needsOnboarding = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Log In")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VStack(spacing: 16) {
                    // Apple Sign In Button
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            viewModel.handleSignInWithAppleRequest(request)
                        },
                        onCompletion: { result in
                            viewModel.handleSignInWithAppleCompletion(result)
                            if viewModel.logStatus {
                                checkOnboardingStatus()
                            }
                        }
                    )
                    .frame(height: 44)
                    .padding(.horizontal)
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                                        
                    
                    // Google Sign In Button
                    Button(action: {
                        Task {
                            if let clientID = FirebaseApp.app()?.options.clientID {
                                let config = GIDConfiguration(clientID: clientID)
                                GIDSignIn.sharedInstance.configuration = config
                                
                                do {
                                    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                          let window = windowScene.windows.first,
                                          let rootViewController = window.rootViewController else {
                                        return
                                    }
                                    
                                    let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
                                    viewModel.logGoogleUser(user: signInResult.user)
                                    if viewModel.logStatus {
                                        checkOnboardingStatus()
                                    }
                                } catch {
                                    print("Google Sign In Error:", error.localizedDescription)
                                }
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "g.circle")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                            
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .dark ? .white : .black)
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                        .cornerRadius(8)
                        .padding()
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 32)
            .navigationDestination(isPresented: $needsOnboarding) {
                OnboardingView()
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $isLoggedIn) {
                HomeView()
                    .navigationBarBackButtonHidden(true)
            }
            .alert(viewModel.errorMessage, isPresented: $viewModel.showError) {}
            .task {
                if viewModel.logStatus {
                    checkOnboardingStatus()
                }
            }
        }
    }
    
    private func checkOnboardingStatus() {
        Task {
            await userViewModel.fetchUserData()
            if let user = userViewModel.user {
                if user.onboardingComplete {
                    isLoggedIn = true
                } else {
                    needsOnboarding = true
                }
            }
        }
    }
}

extension UIApplication {
    func rootController() -> UIViewController {
        guard let window = connectedScenes.first as? UIWindowScene else { return .init() }
        guard let viewController = window.windows.first?.rootViewController else { return .init() }
        return viewController
    }
}

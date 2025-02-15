import SwiftUI
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import Firebase
import CryptoKit
import FirebaseFunctions

@MainActor
class LoginViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var shouldNavigateToHome: Bool = false
    @Published var showIntroduction: Bool = false
    @AppStorage("log_status") var logStatus: Bool = false
    
    private var currentNonce: String?
    private lazy var functions = Functions.functions()
    
    // MARK: - Apple Sign In
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func signInWithApple(onboardingVM: OnboardingViewModel, result: Result<ASAuthorization, Error>) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            switch result {
            case .success(let authorization):
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                   let nonce = currentNonce,
                   let idTokenString = String(data: appleIDCredential.identityToken!, encoding: .utf8) {
                    
                    let credential = OAuthProvider.credential(
                        providerID: AuthProviderID.apple,
                        idToken: idTokenString,
                        rawNonce: nonce
                    )
                    
                    let authResult = try await Auth.auth().signIn(with: credential)
                    print("Apple login successful: \(String(describing: authResult.user.email))")
                    
                    // Store onboarding data with retry logic
//                    try await storeOnboardingData(onboardingVM: onboardingVM)
                    
                    self.logStatus = true
                    self.shouldNavigateToHome = true
                    
                } else {
                    throw NSError(domain: "LoginError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid Apple credential"])
                }
                
            case .failure(let error):
                throw error
            }
        } catch {
            handleAuthError(error)
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(onboardingVM: OnboardingViewModel) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.missingClientID
                
            }
            
            let config = GIDConfiguration(clientID: clientID)
            GIDSignIn.sharedInstance.configuration = config
            
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else {
                throw AuthError.noRootViewController
            }
            
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.missingToken
            }
            
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            print("Google sign in successful: \(String(describing: authResult.user.email))")
            
            // Store onboarding data with retry logic
//            try await storeOnboardingData(onboardingVM: onboardingVM)
            
            self.logStatus = true
            self.shouldNavigateToHome = true
            
        } catch {
            handleAuthError(error)
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        do {
            guard let currentUser = Auth.auth().currentUser else {
                print("No user currently signed in")
                return
            }
            
            let providers = currentUser.providerData.map { $0.providerID }
            print("Current providers: \(providers)")
            
            // Sign out from providers
            for provider in providers {
                switch provider {
                case "google.com":
                    GIDSignIn.sharedInstance.signOut()
                    print("Signed out from Google")
                    
                case "apple.com":
                    print("Apple sign out handled by Firebase Auth")
                    
                default:
                    print("Unknown provider: \(provider)")
                }
            }
            
            try Auth.auth().signOut()
            print("Signed out from Firebase")
            
            await MainActor.run {
                self.logStatus = false
                self.shouldNavigateToHome = false
                self.showIntroduction = true
            }
            
        } catch {
            handleAuthError(error)
        }
    }
    
    // MARK: - Helper Functions
    
    private func storeOnboardingData(onboardingVM: OnboardingViewModel, retryCount: Int = 3) async throws {
        do {
            try await onboardingVM.storeOnboardingDataToFirestore()
        } catch {
            if retryCount > 0 {
                print("Retrying onboarding data storage. Attempts remaining: \(retryCount - 1)")
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                try await storeOnboardingData(onboardingVM: onboardingVM, retryCount: retryCount - 1)
            } else {
                print("Failed to store onboarding data after all retries")
                throw error
            }
        }
    }
    
    private func handleAuthError(_ error: Error) {
        print("Authentication error: \(error)")
        
        let errorMessage: String
        
        switch error {
        case let functionsError as NSError where functionsError.domain == FunctionsErrorDomain:
            errorMessage = "Server error. Please try again later."
            
        case let authError as AuthError:
            errorMessage = authError.localizedDescription
            
        case let nsError as NSError where nsError.domain == "LoginError":
            errorMessage = nsError.localizedDescription
            
        default:
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        self.errorMessage = errorMessage
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}

// MARK: - Custom Error Types

enum AuthError: LocalizedError {
    case missingClientID
    case noRootViewController
    case missingToken
    
    var errorDescription: String? {
        switch self {
        case .missingClientID:
            return "Unable to configure Google Sign In. Please try again later."
        case .noRootViewController:
            return "Unable to present sign in. Please try again."
        case .missingToken:
            return "Authentication failed. Please try again."
        }
    }
}

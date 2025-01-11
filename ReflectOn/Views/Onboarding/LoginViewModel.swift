import SwiftUI
import Firebase
import FirebaseAuth
import AuthenticationServices
import GoogleSignIn
import CryptoKit

@MainActor
final class LoginViewModel: NSObject, ObservableObject {
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @AppStorage("log_status") var logStatus: Bool = false
    
    // Sign in with Apple helper
    private var currentNonce: String?
    
    // MARK: - Sign in with Apple
    func startSignInWithAppleFlow() {
        let nonce = randomNonceString()
        currentNonce = nonce
        // The request is handled by the SignInWithAppleButton automatically
    }
    
    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let nonce = currentNonce {
                guard let idTokenString = String(data: appleIDCredential.identityToken!, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDCredential.identityToken!)")
                    return
                }
                
                let credential = OAuthProvider.credential(
                    providerID: AuthProviderID.apple,
                    idToken: idTokenString,
                    rawNonce: nonce
                )
                
                Task {
                    do {
                        try await Auth.auth().signIn(with: credential)
                        await MainActor.run {
                            self.logStatus = true
                            print("Apple login successful, logStatus set to true")
                        }
                    } catch {
                        print("Error signing in with Apple: \(error)")
                    }
                }
            }
        case .failure(let error):
            print("Sign in with Apple failed: \(error)")
        }
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
    
    // MARK: - Sign in with Google
    func logGoogleUser(user: GIDGoogleUser) async throws {
        guard let idToken = user.idToken else { return }
        let accessToken = user.accessToken
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken.tokenString,
            accessToken: accessToken.tokenString
        )
        // If Auth.auth().signIn(with:) is async, this is a real suspend point
        try await Auth.auth().signIn(with: credential)
        
        // Update your model states
        self.logStatus = true
        print("Google login successful, logStatus set to true")
    }
    
    func signOut() async {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.logStatus = false
        } catch {
            self.errorMessage = "Failed to sign out: \(error.localizedDescription)"
            self.showError = true
        }
    }
}

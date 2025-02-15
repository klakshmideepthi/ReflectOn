import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.7
    @State private var navigateToOnboarding = false
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Spacer()
                    
                    // SF Symbol Icon
                    Image(systemName: "sharedwithyou")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)
                        .foregroundStyle(Color.theme.accent.gradient)
                        .padding(.bottom, 20)
                    
                    // App Name
                    Text("ReflectOn")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(Color.theme.text.primary)
                    
                    // Tagline
                    Text("Reflect deeply, grow daily")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.theme.text.secondary)
                        .padding(.top, 4)
                    
                    Spacer()
                    
                    // Powered by AI text at bottom
                    HStack(spacing: 4) {
                        Text("Powered By AI")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.theme.text.secondary)
                        
                        Image(systemName: "sparkles")
                            .foregroundColor(Color.theme.text.secondary)
                    }
                    .padding(.bottom, 20)
                }
                .opacity(opacity)
                .scaleEffect(scale)
            }
            .onAppear {
                withAnimation(.easeIn(duration: 0.7)) {
                    opacity = 1
                    scale = 1
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    navigateToOnboarding = true
                }
            }
            .navigationDestination(isPresented: $navigateToOnboarding) {
                if logStatus {
                    HomeView()
                        .navigationBarBackButtonHidden(true)
                } else {
                    OnboardingView()
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

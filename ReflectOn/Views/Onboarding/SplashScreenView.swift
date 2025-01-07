import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.7
    @State private var navigateToOnboarding = false
    @AppStorage("log_status") var logStatus: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primary))
                        .scaleEffect(1.5)
                        .padding(.top, 20)
                    
                    Text("ReflectOn")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Your Daily Reflection Companion")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)  
                }
                .opacity(opacity)
                .scaleEffect(scale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fill entire screen
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
                    WelcomePageView()
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}

import SwiftUI

struct WelcomePageView: View {
    @State private var showLoginView = false
    @State private var startOnboarding = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Welcome to ReflectOn!")
                        .font(.largeTitle)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding()

                    Spacer() // Pushes the content towards the top

                    VStack(spacing: 16) {
                        Text("Your personal AI companion for daily reflection and mindful growth")
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)

                        Text("Transform your thoughts into meaningful insights")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal)
                    }

                    Spacer() // Pushes the buttons towards the bottom

                    VStack(spacing: 16) {
                        Button(action: {
                            startOnboarding = true
                        }) {
                            Text("Get Started for Free")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        HStack(spacing: 4) {
                            Text("Already have an account?")
                            Button("Log in") {
                                showLoginView = true
                            }
                        }
                    }
                    .padding()
                }
                .padding(.vertical, 32)
                // Safe area insets applied to the main VStack
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 0)
                }
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 0)
                }
            }
            .navigationDestination(isPresented: $startOnboarding) {
                OnboardingView()
                    .navigationBarBackButtonHidden(true)
            }
            .navigationDestination(isPresented: $showLoginView) {
                LoginView()
                    .navigationBarBackButtonHidden(true)
            }
        }
    }
}

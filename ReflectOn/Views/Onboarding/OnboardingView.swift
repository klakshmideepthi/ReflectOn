import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentStep = 1
    @State private var isOnboardingComplete = false
    @AppStorage("log_status") var logStatus: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    // Content Area
                    TabView(selection: $currentStep) {
                        FocusAreasSelectionView(currentStep: $currentStep, selectedAreas: $viewModel.selectedFocusAreas)
                            .tag(1)
                        
                        AgeView(currentStep: $currentStep, age: Binding(
                            get: { String(viewModel.age) },
                            set: { if let age = Int($0) { viewModel.age = age } }
                        ))
                            .tag(2)
                        
                        GenderView(currentStep: $currentStep, gender: $viewModel.gender)
                            .tag(3)
                        
                        ReminderSetupView(currentStep: $currentStep, reminderTime: $viewModel.reminderTime)
                            .tag(4)
                        
                        PaywallView(currentStep: $currentStep)
                            .tag(5)
                        
                        LoginView()
                            .tag(6)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    // Bottom Button Area
                    VStack(spacing: 8) {
                        if let validationError = viewModel.validationError {
                            Text(validationError)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button(action: {
                            if viewModel.canProceedFromCurrentStep(currentStep) {
                                if currentStep == 4 {
                                    viewModel.saveUserData { success in
                                        if success {
                                            withAnimation {
                                                currentStep += 1
                                                print("Moving to step \(currentStep)")
                                            }
                                        }
                                    }
                                } else if currentStep < 6 {
                                    withAnimation {
                                        currentStep += 1
                                        print("Moving to step \(currentStep)")
                                    }
                                } else {
                                    isOnboardingComplete = true
                                    print("Completing onboarding")
                                }
                            }
                        }) {
                            Text("Continue")
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(UIColor.systemBackground))
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .navigationDestination(isPresented: $isOnboardingComplete) {
                HomeView()
                    .navigationBarBackButtonHidden(true)
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.error != nil },
                set: { if !$0 { viewModel.error = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.error?.localizedDescription ?? "An unknown error occurred")
            }
        }
    }
} 

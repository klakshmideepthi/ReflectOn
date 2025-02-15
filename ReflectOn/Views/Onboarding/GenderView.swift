import SwiftUI

struct GenderView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    @State private var selectedGender: String = ""
    
    let genderOptions = [
        "Male",
        "Female",
        "Non-Binary",
        "Prefer not to say"
    ]
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                
                Spacer()
                
                Text("Tell us about yourself !")
                    .font(.system(size: 34, weight: .regular))
                    .foregroundColor(.blue)
                
                Text("Your guidence will be tailored\nto your gender")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(.blue.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                
                VStack(spacing: 16) {
                    ForEach(genderOptions, id: \.self) { gender in
                        Button(action: {
                            selectedGender = gender
                            onboardingVM.gender = gender
                            onboardingVM.goToNextStep()
                        }) {
                            HStack {
                                Text(gender)
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                            )
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)
                
                Spacer()
            }
        }
    }
}

#Preview {
    GenderView(onboardingVM: OnboardingViewModel())
}

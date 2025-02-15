import SwiftUI

public struct Question {
    let text: String
    let options: [String]
}

public struct BaselineQuestionsView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    let questionSet: Int
    @State private var selectedOption: String?
    
    // Questions for each set
    private var questions: [Question] = [
        Question(
            text: "How often do you pause to reflect on your emotions?",
            options: [
                "Multiple times a day",
                "Once a day",
                "A few times a week",
                "Almost never",
                "Not sure"
            ]
        ),
        Question(
            text: "What helps you feel most grounded?",
            options: [
                "Nature or Outdoor activities",
                "Creative hobbies",
                "Alone time or meditation",
                "Conversations with loved ones",
                "Not sure"
            ]
        ),
        Question(
            text: "What holds you back from reflecting on your thoughts and emotions?",
            options: [
                "Lack of time",
                "Overwhelm or uncertainty",
                "Distractions",
                "Difficulty identifying feelings",
                "Fear of confronting emotions"
            ]
        )
    ]
    
    private var currentQuestion: Question {
        questions[questionSet - 1]
    }
    
    init(onboardingVM: OnboardingViewModel, questionSet: Int) {
        self.onboardingVM = onboardingVM
        self.questionSet = questionSet
    }
    
    public var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Question Text
                Text(currentQuestion.text)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Options
                VStack(spacing: 12) {
                    ForEach(currentQuestion.options, id: \.self) { option in
                        Button(action: {
                            selectedOption = option
                            onboardingVM.baselineAnswers["Q\(questionSet)"] = option
                        }) {
                            Text(option)
                                .font(.system(size: 16))
                                .foregroundColor(selectedOption == option ? .white : .blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedOption == option ? Color.blue : Color.gray.opacity(0.3))
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                Button(action: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        if questionSet < 3 {
                            onboardingVM.goToNextStep()
                        } else {
                            onboardingVM.goToNextStep()
                        }
                    }
                }) {
                    Text("TAP TO CONTINUE")
                        .font(.caption)
                        .foregroundColor(selectedOption != nil ? .blue : .gray)
                        .padding(.bottom, 40)
                }
                .disabled(selectedOption == nil)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

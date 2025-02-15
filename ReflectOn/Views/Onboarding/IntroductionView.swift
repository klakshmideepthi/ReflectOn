import SwiftUI

struct IntroductionView: View {
    @ObservedObject var onboardingVM: OnboardingViewModel
    @State private var showContinueButton = false
    @State private var highlightedRanges: [Range<String.Index>] = []
    
    // The full text to be displayed
    private let introText1 = """
    The app provides a user-friendly and accessible self-reflection experience through an AI-powered conversational interface that addresses the challenge of making self-reflection a daily habit by offering engaging and personalized sessions that encourage users to explore their thoughts, emotions, and experiences.
    """
    
    private let introText = """
    The app provides a user-friendly and accessible self-reflection experience through an AI-powered conversational interface.
    """
    
    // Words to be highlighted with their colors
    private let highlightedWords: [(String, Color)] = [
        ("conversational interface", .blue),
        ("personalized", .blue)
    ]
    
    var body: some View {
        ZStack {
            Color.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Streaming text with highlights
                AdvancedStreamingText(
                    introText,
                    speed: 0.05,
                    cursor: "",
                    cursorBlink: true,
                    autoStart: true,
                    onComplete: {
                        withAnimation(.easeIn(duration: 0.5)) {
                            showContinueButton = true
                            // Add highlights after text is complete
                            highlightWords()
                        }
                    }
                )
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(Color.theme.text.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Continue button
                if showContinueButton {
                    Text("Tap to continue")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.theme.text.secondary)
                        .opacity(0.8)
                        .padding(.bottom, 40)
                        .transition(.opacity)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if showContinueButton {
                onboardingVM.goToNextStep()
            }
        }
    }
    
    private func highlightWords() {
        for (word, _) in highlightedWords {
            if let range = introText.range(of: word) {
                highlightedRanges.append(range)
            }
        }
    }
}

// Custom text modifier to apply highlights
struct HighlightedText: View {
    let text: String
    let highlightedRanges: [Range<String.Index>]
    let highlightColor: Color
    let baseColor: Color
    
    var body: some View {
        let attributedString = NSMutableAttributedString(string: text)
        
        // Apply base color
        attributedString.addAttribute(
            .foregroundColor,
            value: baseColor,
            range: NSRange(location: 0, length: text.count)
        )
        
        // Apply highlights
        for range in highlightedRanges {
            let nsRange = NSRange(range, in: text)
            attributedString.addAttribute(
                .foregroundColor,
                value: highlightColor,
                range: nsRange
            )
        }
        
        return Text(AttributedString(attributedString))
    }
}

// Preview
#Preview {
    IntroductionView(onboardingVM: OnboardingViewModel())
}

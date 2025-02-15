import SwiftUI

struct StreamingText: View {
    let fullText: String
    let speed: Double
    @State private var displayedText: String = ""
    @State private var isAnimating: Bool = true
    
    init(_ text: String, speed: Double = 0.05) {
        self.fullText = text
        self.speed = speed
    }
    
    var body: some View {
        Text(displayedText)
            .onAppear {
                animateText()
            }
    }
    
    private func animateText() {
        var charIndex = 0
        displayedText = ""
        
        Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
            if charIndex < fullText.count && isAnimating {
                let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
                displayedText += String(fullText[index])
                charIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    // Function to restart animation
    func restart() {
        isAnimating = true
        animateText()
    }
    
    // Function to stop animation
    func stop() {
        isAnimating = false
    }
}

// Enhanced version with more control and features
struct AdvancedStreamingText: View {
    let fullText: String
    let speed: Double
    let cursor: String
    let cursorBlink: Bool
    let autoStart: Bool
    let onComplete: (() -> Void)?
    
    @State private var displayedText: String = ""
    @State private var isAnimating: Bool = false
    @State private var showCursor: Bool = true
    
    init(
        _ text: String,
        speed: Double = 0.05,
        cursor: String = "|",
        cursorBlink: Bool = true,
        autoStart: Bool = true,
        onComplete: (() -> Void)? = nil
    ) {
        self.fullText = text
        self.speed = speed
        self.cursor = cursor
        self.cursorBlink = cursorBlink
        self.autoStart = autoStart
        self.onComplete = onComplete
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text(displayedText)
            if isAnimating || (!isAnimating && displayedText != fullText) {
                Text(cursor)
                    .opacity(showCursor ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(), value: showCursor)
            }
        }
        .onAppear {
            if cursorBlink {
                withAnimation {
                    showCursor.toggle()
                }
            }
            if autoStart {
                start()
            }
        }
    }
    
    private func animateText() {
        var charIndex = displayedText.count
        
        Timer.scheduledTimer(withTimeInterval: speed, repeats: true) { timer in
            if charIndex < fullText.count && isAnimating {
                let index = fullText.index(fullText.startIndex, offsetBy: charIndex)
                displayedText += String(fullText[index])
                charIndex += 1
            } else {
                timer.invalidate()
                if charIndex >= fullText.count {
                    isAnimating = false
                    onComplete?()
                }
            }
        }
    }
    
    // Public control functions
    func start() {
        isAnimating = true
        animateText()
    }
    
    func pause() {
        isAnimating = false
    }
    
    func resume() {
        isAnimating = true
        animateText()
    }
    
    func reset() {
        isAnimating = false
        displayedText = ""
    }
    
    func complete() {
        displayedText = fullText
        isAnimating = false
        onComplete?()
    }
}

#Preview {
    VStack(spacing: 20) {
        // Simple streaming text
        StreamingText("Hello, this is a simple streaming text!")
        
        // Advanced streaming text with cursor and controls
        AdvancedStreamingText(
            "This is an advanced streaming text with more features!",
            speed: 0.08,
            cursor: "▋",
            cursorBlink: true,
            onComplete: {
                print("Animation completed!")
            }
        )
    }
    .padding()
}

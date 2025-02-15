import SwiftUI

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let background = Color("BackgroundColor")
    let foreground = Color("ForegroundColor")
    let accent = Color("AccentColor")
    let text = TextColors()
    
    struct TextColors {
        let primary = Color("TextPrimary")
        let secondary = Color("TextSecondary")
    }
}

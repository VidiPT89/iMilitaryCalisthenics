import SwiftUI

/// Brand palette shared across the developer's native apps (ividi.dev identity).
enum Theme {
    static let background = Color(hex: 0x0a0a0f)
    static let panel = Color(hex: 0x0d0d18)
    static let panel2 = Color(hex: 0x12121f)
    static let accent = Color(hex: 0xf99c00)
    static let accentLight = Color(hex: 0xfcbb00)
    static let accentDark = Color(hex: 0xdd7400)
    static let text = Color(hex: 0xe2e8f0)
    static let textDim = Color(hex: 0x94a3b8)
    static let textFaint = Color(hex: 0x5b6474)
    static let danger = Color(hex: 0xef4444)
    static let ok = Color(hex: 0x22c55e)

    static let accentGradient = LinearGradient(
        colors: [accent, accentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cornerRadius: CGFloat = 18
    static let springAnimation = Animation.spring(response: 0.45, dampingFraction: 0.75)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct PanelBackground: ViewModifier {
    var elevated: Bool = false
    func body(content: Content) -> some View {
        content
            .background(elevated ? Theme.panel2 : Theme.panel)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Theme.accent.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func panelBackground(elevated: Bool = false) -> some View {
        modifier(PanelBackground(elevated: elevated))
    }
}

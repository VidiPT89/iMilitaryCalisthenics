import SwiftUI

enum ThemeMode: String, CaseIterable {
    case light, dark, system
}

/// A concrete set of brand colors for one appearance (dark or light).
struct ThemePalette {
    let background: Color
    let panel: Color
    let panel2: Color
    let accent: Color
    let accentLight: Color
    let accentDark: Color
    let text: Color
    let textDim: Color
    let textFaint: Color
    let danger: Color
    let ok: Color

    static let dark = ThemePalette(
        background: Color(hex: 0x0a0a0f),
        panel: Color(hex: 0x0d0d18),
        panel2: Color(hex: 0x12121f),
        accent: Color(hex: 0xf99c00),
        accentLight: Color(hex: 0xfcbb00),
        accentDark: Color(hex: 0xdd7400),
        text: Color(hex: 0xe2e8f0),
        textDim: Color(hex: 0x94a3b8),
        textFaint: Color(hex: 0x5b6474),
        danger: Color(hex: 0xef4444),
        ok: Color(hex: 0x22c55e)
    )

    // Same ividi.dev orange/burnt-yellow family, deepened where it doubles as
    // text/icon color so it still clears ~4:1 contrast against the light background.
    static let light = ThemePalette(
        background: Color(hex: 0xf7f4ef),
        panel: Color(hex: 0xffffff),
        panel2: Color(hex: 0xefe9df),
        accent: Color(hex: 0xb8590a),
        accentLight: Color(hex: 0xf99c00),
        accentDark: Color(hex: 0x8f4300),
        text: Color(hex: 0x17140f),
        textDim: Color(hex: 0x5c574f),
        textFaint: Color(hex: 0x8f897e),
        danger: Color(hex: 0xc62828),
        ok: Color(hex: 0x15803d)
    )
}

/// Live, observable brand theme. Views read `Theme.shared` colors directly;
/// switching `mode` (or the system appearance, when following it) updates
/// every screen automatically since Observation tracks the property reads.
@Observable
final class Theme {
    static let shared = Theme()

    private static let modeKey = "themeMode"

    var mode: ThemeMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: Self.modeKey) }
    }

    /// Updated by RootView from the environment's actual system appearance.
    var systemIsDark: Bool = true

    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.modeKey), let saved = ThemeMode(rawValue: raw) {
            mode = saved
        } else {
            mode = .dark
        }
    }

    var isDark: Bool {
        switch mode {
        case .dark: return true
        case .light: return false
        case .system: return systemIsDark
        }
    }

    private var palette: ThemePalette { isDark ? .dark : .light }

    var background: Color { palette.background }
    var panel: Color { palette.panel }
    var panel2: Color { palette.panel2 }
    var accent: Color { palette.accent }
    var accentLight: Color { palette.accentLight }
    var accentDark: Color { palette.accentDark }
    var text: Color { palette.text }
    var textDim: Color { palette.textDim }
    var textFaint: Color { palette.textFaint }
    var danger: Color { palette.danger }
    var ok: Color { palette.ok }

    var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentLight], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    let cornerRadius: CGFloat = 18
    let springAnimation = Animation.spring(response: 0.45, dampingFraction: 0.75)
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
    let theme = Theme.shared
    func body(content: Content) -> some View {
        content
            .background(elevated ? theme.panel2 : theme.panel)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cornerRadius, style: .continuous)
                    .stroke(theme.accent.opacity(0.12), lineWidth: 1)
            )
    }
}

extension View {
    func panelBackground(elevated: Bool = false) -> some View {
        modifier(PanelBackground(elevated: elevated))
    }
}

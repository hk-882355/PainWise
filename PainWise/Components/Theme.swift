import SwiftUI

// MARK: - Color Theme
extension Color {
    // Primary
    static let appPrimary = Color(hex: "13ec80")

    // Background
    static let backgroundLight = Color(hex: "f6f8f7")
    static let backgroundDark = Color(hex: "102219")

    // Surface (Cards)
    static let surfaceLight = Color.white
    static let surfaceDark = Color(hex: "1a3326")
    static let surfaceHighlight = Color(hex: "234836")

    // Text
    static let textSecondary = Color(hex: "92c9ad")

    // Semantic Colors
    static let painMild = Color.appPrimary
    static let painModerate = Color.yellow
    static let painSevere = Color.orange
    static let painExtreme = Color.red
}

// MARK: - Hex Color Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Adaptive Colors
struct AppColors {
    @Environment(\.colorScheme) var colorScheme

    var background: Color {
        colorScheme == .dark ? .backgroundDark : .backgroundLight
    }

    var surface: Color {
        colorScheme == .dark ? .surfaceDark : .surfaceLight
    }

    var text: Color {
        colorScheme == .dark ? .white : Color(hex: "11221a")
    }

    var secondaryText: Color {
        colorScheme == .dark ? .textSecondary : .gray
    }
}

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(colorScheme == .dark ? Color.surfaceDark : Color.surfaceLight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0 : 0.05), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(colorScheme == .dark ? Color.white.opacity(0.05) : Color.gray.opacity(0.1), lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(Color.backgroundDark)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.appPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(colorScheme == .dark ? .white : Color(hex: "11221a"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(colorScheme == .dark ? Color.surfaceHighlight : Color.gray.opacity(0.1))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Typography with Dynamic Type Support
extension Font {
    static let appTitle = Font.system(size: 24, weight: .bold)
    static let appHeadline = Font.system(size: 18, weight: .bold)
    static let appSubheadline = Font.system(size: 16, weight: .semibold)
    static let appBody = Font.system(size: 14, weight: .regular)
    static let appCaption = Font.system(size: 12, weight: .medium)
    static let appSmall = Font.system(size: 10, weight: .medium)
}

// MARK: - Accessibility Scaling
struct AccessibilityScaling {
    /// Use @ScaledMetric for Dynamic Type support
    /// Example: @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 24

    static let minTouchTarget: CGFloat = 44  // Apple HIG minimum
    static let recommendedTouchTarget: CGFloat = 48
}

// MARK: - High Contrast Colors (for Accessibility)
extension Color {
    /// Higher contrast version of textSecondary for improved readability
    static let textSecondaryHighContrast = Color(hex: "a8d9c0")

    /// Higher contrast gray for use on dark backgrounds
    static let grayHighContrast = Color(hex: "b8c8c0")
}

// MARK: - Pain Level Colors
extension PainSeverity {
    var swiftUIColor: Color {
        switch self {
        case .mild: return .painMild
        case .moderate: return .painModerate
        case .severe: return .painSevere
        case .extreme: return .painExtreme
        }
    }
}

func painLevelColor(for level: Int) -> Color {
    switch level {
    case 0...2: return .painMild
    case 3...5: return .painModerate
    case 6...8: return .painSevere
    default: return .painExtreme
    }
}

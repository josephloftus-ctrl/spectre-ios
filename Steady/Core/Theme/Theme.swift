import SwiftUI

// MARK: - Steady Theme
// Dark mode first design with slate blue accent

struct SteadyTheme {

    // MARK: - Brand Colors

    /// Primary slate blue - matches web app primary: hsl(207 25% 48%)
    static let primary = Color(hue: 207/360, saturation: 0.25, brightness: 0.48)

    /// Lighter primary for hover/active states
    static let primaryLight = Color(hue: 207/360, saturation: 0.28, brightness: 0.60)

    /// Darker primary for pressed states
    static let primaryDark = Color(hue: 207/360, saturation: 0.32, brightness: 0.35)

    // MARK: - Background Colors (Dark Mode First)

    /// Main background - dark slate: hsl(220 13% 12%)
    static let background = Color(hue: 220/360, saturation: 0.13, brightness: 0.12)

    /// Card/elevated surface background: hsl(220 13% 15%)
    static let cardBackground = Color(hue: 220/360, saturation: 0.13, brightness: 0.15)

    /// Secondary/muted background: hsl(220 10% 20%)
    static let secondaryBackground = Color(hue: 220/360, saturation: 0.10, brightness: 0.20)

    /// Tertiary background for nested elements: hsl(220 10% 22%)
    static let tertiaryBackground = Color(hue: 220/360, saturation: 0.10, brightness: 0.22)

    // MARK: - Text Colors

    /// Primary text - light gray: hsl(60 9% 94%)
    static let textPrimary = Color(hue: 60/360, saturation: 0.09, brightness: 0.94)

    /// Secondary/muted text: hsl(220 10% 60%)
    static let textSecondary = Color(hue: 220/360, saturation: 0.10, brightness: 0.60)

    /// Tertiary/placeholder text: hsl(220 10% 45%)
    static let textTertiary = Color(hue: 220/360, saturation: 0.10, brightness: 0.45)

    // MARK: - Border Colors

    /// Default border: hsl(220 10% 24%)
    static let border = Color(hue: 220/360, saturation: 0.10, brightness: 0.24)

    /// Subtle border for cards: hsl(220 10% 20%)
    static let borderSubtle = Color(hue: 220/360, saturation: 0.10, brightness: 0.20)

    // MARK: - Semantic Colors

    /// Success - green: hsl(142 71% 45%)
    static let success = Color(hue: 142/360, saturation: 0.71, brightness: 0.45)

    /// Warning - amber: hsl(38 92% 50%)
    static let warning = Color(hue: 38/360, saturation: 0.92, brightness: 0.50)

    /// Error/destructive - red: hsl(0 63% 45%)
    static let destructive = Color(hue: 0, saturation: 0.63, brightness: 0.45)

    /// Info - cyan blue: hsl(217 91% 60%)
    static let info = Color(hue: 217/360, saturation: 0.91, brightness: 0.60)

    // MARK: - Spacing

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    struct Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 20
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    static let cardShadow = Color.black.opacity(0.3)
    static let elevatedShadow = Color.black.opacity(0.5)
}

// MARK: - Color Extensions

extension Color {
    static let steadyPrimary = SteadyTheme.primary
    static let steadyPrimaryLight = SteadyTheme.primaryLight
    static let steadyPrimaryDark = SteadyTheme.primaryDark

    static let steadyBackground = SteadyTheme.background
    static let steadyCard = SteadyTheme.cardBackground
    static let steadySecondary = SteadyTheme.secondaryBackground

    static let steadyText = SteadyTheme.textPrimary
    static let steadyTextSecondary = SteadyTheme.textSecondary
    static let steadyTextTertiary = SteadyTheme.textTertiary

    static let steadyBorder = SteadyTheme.border

    static let steadySuccess = SteadyTheme.success
    static let steadyWarning = SteadyTheme.warning
    static let steadyDestructive = SteadyTheme.destructive
    static let steadyInfo = SteadyTheme.info
}

// MARK: - View Modifiers

struct SteadyCardStyle: ViewModifier {
    var padding: CGFloat = SteadyTheme.Spacing.md

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(SteadyTheme.cardBackground)
            .cornerRadius(SteadyTheme.Radius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: SteadyTheme.Radius.lg)
                    .stroke(SteadyTheme.borderSubtle, lineWidth: 1)
            )
            .shadow(color: SteadyTheme.cardShadow, radius: 8, x: 0, y: 4)
    }
}

struct SteadyPrimaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, SteadyTheme.Spacing.lg)
            .padding(.vertical, SteadyTheme.Spacing.sm + 4)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(
                configuration.isPressed ? SteadyTheme.primaryDark : SteadyTheme.primary
            )
            .cornerRadius(SteadyTheme.Radius.md)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SteadySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundColor(SteadyTheme.primary)
            .padding(.horizontal, SteadyTheme.Spacing.lg)
            .padding(.vertical, SteadyTheme.Spacing.sm + 4)
            .background(SteadyTheme.secondaryBackground)
            .cornerRadius(SteadyTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: SteadyTheme.Radius.md)
                    .stroke(SteadyTheme.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SteadyGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundColor(SteadyTheme.textSecondary)
            .padding(.horizontal, SteadyTheme.Spacing.md)
            .padding(.vertical, SteadyTheme.Spacing.sm)
            .background(configuration.isPressed ? SteadyTheme.secondaryBackground : Color.clear)
            .cornerRadius(SteadyTheme.Radius.md)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func steadyCard(padding: CGFloat = SteadyTheme.Spacing.md) -> some View {
        modifier(SteadyCardStyle(padding: padding))
    }

    func steadyPrimaryButton(fullWidth: Bool = false) -> some View {
        buttonStyle(SteadyPrimaryButtonStyle(isFullWidth: fullWidth))
    }

    func steadySecondaryButton() -> some View {
        buttonStyle(SteadySecondaryButtonStyle())
    }

    func steadyGhostButton() -> some View {
        buttonStyle(SteadyGhostButtonStyle())
    }
}

import SwiftUI

// MARK: - Steady Button Component

struct SteadyButton: View {
    let title: String
    let icon: String?
    let style: Style
    let isFullWidth: Bool
    let isLoading: Bool
    let action: () -> Void

    enum Style {
        case primary
        case secondary
        case ghost
        case destructive
    }

    init(
        _ title: String,
        icon: String? = nil,
        style: Style = .primary,
        isFullWidth: Bool = false,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isFullWidth = isFullWidth
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: SteadyTheme.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.body.weight(.medium))
                }

                Text(title)
                    .font(.body.weight(.semibold))
            }
            .foregroundColor(foregroundColor)
            .padding(.horizontal, SteadyTheme.Spacing.lg)
            .padding(.vertical, SteadyTheme.Spacing.sm + 4)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundColor)
            .cornerRadius(SteadyTheme.Radius.md)
            .overlay(borderOverlay)
        }
        .disabled(isLoading)
        .buttonStyle(SteadyButtonPressStyle())
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .steadyPrimary
        case .ghost:
            return .steadyTextSecondary
        case .destructive:
            return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .steadyPrimary
        case .secondary:
            return .steadySecondary
        case .ghost:
            return .clear
        case .destructive:
            return .steadyDestructive
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .secondary:
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.md)
                .stroke(SteadyTheme.border, lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

// MARK: - Icon Button

struct SteadyIconButton: View {
    let icon: String
    let size: Size
    let style: SteadyButton.Style
    let action: () -> Void

    enum Size {
        case small
        case medium
        case large

        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }

        var iconFont: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .title3
            }
        }
    }

    init(
        icon: String,
        size: Size = .medium,
        style: SteadyButton.Style = .ghost,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(size.iconFont)
                .foregroundColor(foregroundColor)
                .frame(width: size.dimension, height: size.dimension)
                .background(backgroundColor)
                .cornerRadius(SteadyTheme.Radius.md)
        }
        .buttonStyle(SteadyButtonPressStyle())
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .ghost:
            return .steadyTextSecondary
        case .destructive:
            return .steadyDestructive
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .steadyPrimary
        case .secondary:
            return .steadySecondary
        case .ghost:
            return .clear
        case .destructive:
            return .steadySecondary
        }
    }
}

// MARK: - Floating Action Button

struct SteadyFAB: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [.steadyPrimary, .steadyPrimaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(SteadyTheme.Radius.xl)
                .shadow(color: SteadyTheme.primary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(SteadyButtonPressStyle())
    }
}

// MARK: - Press Animation Style

struct SteadyButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.steadyBackground.ignoresSafeArea()

        VStack(spacing: SteadyTheme.Spacing.lg) {
            SteadyButton("Primary Button", icon: "plus") {
                print("Primary tapped")
            }

            SteadyButton("Secondary", icon: "gear", style: .secondary) {
                print("Secondary tapped")
            }

            SteadyButton("Ghost Button", style: .ghost) {
                print("Ghost tapped")
            }

            SteadyButton("Delete", icon: "trash", style: .destructive) {
                print("Delete tapped")
            }

            HStack(spacing: SteadyTheme.Spacing.md) {
                SteadyIconButton(icon: "plus", style: .primary) {}
                SteadyIconButton(icon: "gear") {}
                SteadyIconButton(icon: "trash", style: .destructive) {}
            }

            Spacer()

            HStack {
                Spacer()
                SteadyFAB(icon: "plus") {
                    print("FAB tapped")
                }
            }
            .padding()
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

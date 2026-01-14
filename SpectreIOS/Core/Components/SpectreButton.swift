import SwiftUI

// MARK: - Spectre Button Component

struct SpectreButton: View {
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
            HStack(spacing: SpectreTheme.Spacing.sm) {
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
            .padding(.horizontal, SpectreTheme.Spacing.lg)
            .padding(.vertical, SpectreTheme.Spacing.sm + 4)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundColor)
            .cornerRadius(SpectreTheme.Radius.md)
            .overlay(borderOverlay)
        }
        .disabled(isLoading)
        .buttonStyle(SpectreButtonPressStyle())
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .spectrePrimary
        case .ghost:
            return .spectreTextSecondary
        case .destructive:
            return .white
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .spectrePrimary
        case .secondary:
            return .spectreSecondary
        case .ghost:
            return .clear
        case .destructive:
            return .spectreDestructive
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .secondary:
            RoundedRectangle(cornerRadius: SpectreTheme.Radius.md)
                .stroke(SpectreTheme.border, lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

// MARK: - Icon Button

struct SpectreIconButton: View {
    let icon: String
    let size: Size
    let style: SpectreButton.Style
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
        style: SpectreButton.Style = .ghost,
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
                .cornerRadius(SpectreTheme.Radius.md)
        }
        .buttonStyle(SpectreButtonPressStyle())
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary, .ghost:
            return .spectreTextSecondary
        case .destructive:
            return .spectreDestructive
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .spectrePrimary
        case .secondary:
            return .spectreSecondary
        case .ghost:
            return .clear
        case .destructive:
            return .spectreSecondary
        }
    }
}

// MARK: - Floating Action Button

struct SpectreFAB: View {
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
                        colors: [.spectrePrimary, .spectrePrimaryDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(SpectreTheme.Radius.xl)
                .shadow(color: SpectreTheme.primary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .buttonStyle(SpectreButtonPressStyle())
    }
}

// MARK: - Press Animation Style

struct SpectreButtonPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.spectreBackground.ignoresSafeArea()

        VStack(spacing: SpectreTheme.Spacing.lg) {
            // Primary buttons
            SpectreButton("Primary Button", icon: "plus") {
                print("Primary tapped")
            }

            SpectreButton("Full Width", isFullWidth: true) {
                print("Full width tapped")
            }

            SpectreButton("Loading...", isLoading: true) {
                print("Loading")
            }

            // Secondary
            SpectreButton("Secondary", icon: "gear", style: .secondary) {
                print("Secondary tapped")
            }

            // Ghost
            SpectreButton("Ghost Button", style: .ghost) {
                print("Ghost tapped")
            }

            // Destructive
            SpectreButton("Delete", icon: "trash", style: .destructive) {
                print("Delete tapped")
            }

            // Icon buttons
            HStack(spacing: SpectreTheme.Spacing.md) {
                SpectreIconButton(icon: "plus", style: .primary) {}
                SpectreIconButton(icon: "gear") {}
                SpectreIconButton(icon: "trash", style: .destructive) {}
            }

            Spacer()

            // FAB
            HStack {
                Spacer()
                SpectreFAB(icon: "plus") {
                    print("FAB tapped")
                }
            }
            .padding()
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

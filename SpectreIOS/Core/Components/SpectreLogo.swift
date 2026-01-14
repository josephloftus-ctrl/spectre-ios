import SwiftUI

// MARK: - Steady Logo Component
// The slate blue branded logo for the Steady app

struct SteadyLogo: View {
    let size: Size
    let showText: Bool

    enum Size {
        case small
        case medium
        case large
        case hero

        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 32
            case .large: return 48
            case .hero: return 80
            }
        }

        var fontSize: Font {
            switch self {
            case .small: return .caption
            case .medium: return .body
            case .large: return .title2
            case .hero: return .largeTitle
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            case .hero: return 12
            }
        }
    }

    init(size: Size = .medium, showText: Bool = true) {
        self.size = size
        self.showText = showText
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            // Logo icon - slate blue shield/chart combo
            ZStack {
                // Background circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                SpectreTheme.primary,
                                SpectreTheme.primaryDark
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.iconSize, height: size.iconSize)

                // Icon
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: size.iconSize * 0.5, weight: .semibold))
                    .foregroundColor(.white)
            }

            if showText {
                Text("Steady")
                    .font(size.fontSize.weight(.bold))
                    .foregroundColor(.spectreText)
            }
        }
    }
}

// MARK: - App Header with Logo

struct SpectreHeader: View {
    let title: String?
    let showLogo: Bool
    let trailingContent: AnyView?

    init(
        title: String? = nil,
        showLogo: Bool = true,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.showLogo = showLogo
        self.trailingContent = AnyView(trailing())
    }

    var body: some View {
        HStack {
            if showLogo {
                SteadyLogo(size: .medium)
            } else if let title = title {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.spectreText)
            }

            Spacer()

            trailingContent
        }
        .padding(.horizontal, SpectreTheme.Spacing.md)
        .padding(.vertical, SpectreTheme.Spacing.sm)
        .background(SpectreTheme.background)
    }
}

// MARK: - Splash/Loading View with Logo

struct SpectreSplashView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.spectreBackground.ignoresSafeArea()

            VStack(spacing: SpectreTheme.Spacing.xl) {
                SteadyLogo(size: .hero, showText: false)
                    .scaleEffect(isAnimating ? 1.0 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.5)

                Text("Steady")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.spectreText)
                    .opacity(isAnimating ? 1.0 : 0)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .spectrePrimary))
                    .scaleEffect(1.2)
                    .opacity(isAnimating ? 1.0 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Preview

#Preview("Logo Sizes") {
    ZStack {
        Color.spectreBackground.ignoresSafeArea()

        VStack(spacing: SpectreTheme.Spacing.xl) {
            SteadyLogo(size: .small)
            SteadyLogo(size: .medium)
            SteadyLogo(size: .large)
            SteadyLogo(size: .hero)

            Divider()
                .background(Color.spectreBorder)

            SteadyLogo(size: .large, showText: false)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Splash Screen") {
    SpectreSplashView()
}

#Preview("Header") {
    ZStack {
        Color.spectreBackground.ignoresSafeArea()

        VStack {
            SpectreHeader {
                SpectreIconButton(icon: "gear") {}
            }

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}

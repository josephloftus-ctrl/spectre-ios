import SwiftUI

// MARK: - Steady Card Component

struct SteadyCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = SteadyTheme.Spacing.md
    var showBorder: Bool = true

    init(
        padding: CGFloat = SteadyTheme.Spacing.md,
        showBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.showBorder = showBorder
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(SteadyTheme.cardBackground)
            .cornerRadius(SteadyTheme.Radius.lg)
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: SteadyTheme.Radius.lg)
                            .stroke(SteadyTheme.borderSubtle, lineWidth: 1)
                    }
                }
            )
            .shadow(color: SteadyTheme.cardShadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Header Card Variant

struct SteadyHeaderCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        SteadyCard {
            VStack(alignment: .leading, spacing: SteadyTheme.Spacing.md) {
                HStack(spacing: SteadyTheme.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.steadyPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.steadyText)

                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.steadyTextSecondary)
                        }
                    }

                    Spacer()
                }

                content
            }
        }
    }
}

// MARK: - Stat Card (for KPIs)

struct SteadyStatCard: View {
    let title: String
    let value: String
    let icon: String
    let trend: Trend?
    let accentColor: Color

    enum Trend {
        case up(String)
        case down(String)
        case neutral(String)

        var color: Color {
            switch self {
            case .up: return .steadySuccess
            case .down: return .steadyDestructive
            case .neutral: return .steadyTextSecondary
            }
        }

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var text: String {
            switch self {
            case .up(let value), .down(let value), .neutral(let value):
                return value
            }
        }
    }

    init(
        title: String,
        value: String,
        icon: String,
        accentColor: Color = .steadyPrimary,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.accentColor = accentColor
        self.trend = trend
    }

    var body: some View {
        SteadyCard(padding: SteadyTheme.Spacing.md) {
            VStack(spacing: SteadyTheme.Spacing.sm) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(accentColor)
                    Spacer()

                    if let trend = trend {
                        HStack(spacing: 2) {
                            Image(systemName: trend.icon)
                                .font(.caption2)
                            Text(trend.text)
                                .font(.caption2.weight(.medium))
                        }
                        .foregroundColor(trend.color)
                    }
                }

                VStack(spacing: 4) {
                    Text(value)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.steadyText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(title)
                        .font(.caption)
                        .foregroundColor(.steadyTextSecondary)
                }
            }
        }
    }
}

#Preview {
    ZStack {
        Color.steadyBackground.ignoresSafeArea()

        ScrollView {
            VStack(spacing: SteadyTheme.Spacing.md) {
                HStack(spacing: SteadyTheme.Spacing.sm) {
                    SteadyStatCard(
                        title: "Total Value",
                        value: "$1.2M",
                        icon: "dollarsign.circle.fill",
                        accentColor: .steadySuccess,
                        trend: .up("12%")
                    )

                    SteadyStatCard(
                        title: "Active Sites",
                        value: "24",
                        icon: "building.2.fill",
                        accentColor: .steadyPrimary
                    )
                }

                SteadyHeaderCard(
                    title: "Recent Activity",
                    subtitle: "Last 24 hours",
                    icon: "clock.fill"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("5 new scans completed")
                            .foregroundColor(.steadyText)
                    }
                }

                SteadyCard {
                    Text("Simple card content")
                        .foregroundColor(.steadyText)
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}

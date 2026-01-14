import SwiftUI

// MARK: - Spectre Card Component

struct SpectreCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = SpectreTheme.Spacing.md
    var showBorder: Bool = true

    init(
        padding: CGFloat = SpectreTheme.Spacing.md,
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
            .background(SpectreTheme.cardBackground)
            .cornerRadius(SpectreTheme.Radius.lg)
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: SpectreTheme.Radius.lg)
                            .stroke(SpectreTheme.borderSubtle, lineWidth: 1)
                    }
                }
            )
            .shadow(color: SpectreTheme.cardShadow, radius: 8, x: 0, y: 4)
    }
}

// MARK: - Header Card Variant

struct SpectreHeaderCard<Content: View>: View {
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
        SpectreCard {
            VStack(alignment: .leading, spacing: SpectreTheme.Spacing.md) {
                HStack(spacing: SpectreTheme.Spacing.sm) {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.spectrePrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.spectreText)

                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.spectreTextSecondary)
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

struct SpectreStatCard: View {
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
            case .up: return .spectreSuccess
            case .down: return .spectreDestructive
            case .neutral: return .spectreTextSecondary
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
        accentColor: Color = .spectrePrimary,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.accentColor = accentColor
        self.trend = trend
    }

    var body: some View {
        SpectreCard(padding: SpectreTheme.Spacing.md) {
            VStack(spacing: SpectreTheme.Spacing.sm) {
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
                        .foregroundColor(.spectreText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(title)
                        .font(.caption)
                        .foregroundColor(.spectreTextSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.spectreBackground.ignoresSafeArea()

        ScrollView {
            VStack(spacing: SpectreTheme.Spacing.md) {
                // Stat cards row
                HStack(spacing: SpectreTheme.Spacing.sm) {
                    SpectreStatCard(
                        title: "Total Value",
                        value: "$1.2M",
                        icon: "dollarsign.circle.fill",
                        accentColor: .spectreSuccess,
                        trend: .up("12%")
                    )

                    SpectreStatCard(
                        title: "Active Sites",
                        value: "24",
                        icon: "building.2.fill",
                        accentColor: .spectrePrimary
                    )

                    SpectreStatCard(
                        title: "Issues",
                        value: "3",
                        icon: "exclamationmark.triangle.fill",
                        accentColor: .spectreWarning,
                        trend: .down("2")
                    )
                }

                // Header card example
                SpectreHeaderCard(
                    title: "Recent Activity",
                    subtitle: "Last 24 hours",
                    icon: "clock.fill"
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("5 new scans completed")
                            .foregroundColor(.spectreText)
                        Text("12 items updated")
                            .foregroundColor(.spectreTextSecondary)
                    }
                }

                // Simple card
                SpectreCard {
                    Text("Simple card content")
                        .foregroundColor(.spectreText)
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}

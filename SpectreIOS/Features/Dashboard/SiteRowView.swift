import SwiftUI

struct SiteRowView: View {
    let site: SiteSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(site.site)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.spectreText)

                HStack(spacing: 8) {
                    statusBadge

                    if site.issueCount > 0 {
                        Text("\(site.issueCount) issue\(site.issueCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.spectreWarning)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedValue)
                    .font(.subheadline)
                    .foregroundColor(.spectreTextSecondary)

                if site.deltaPct != 0 {
                    deltaView
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.spectreTextTertiary)
        }
        .padding(SpectreTheme.Spacing.md)
        .background(SpectreTheme.cardBackground)
        .cornerRadius(SpectreTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: SpectreTheme.Radius.lg)
                .stroke(SpectreTheme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: SpectreTheme.cardShadow, radius: 6, x: 0, y: 3)
    }

    private var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: site.latestTotal)) ?? "$\(Int(site.latestTotal))"
    }

    private var statusBadge: some View {
        let (color, icon) = statusColorAndIcon
        return HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.caption2)
            Text("\(site.healthScore)")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .cornerRadius(4)
    }

    private var statusColorAndIcon: (Color, String) {
        switch site.healthStatus {
        case "critical":
            return (.spectreDestructive, "exclamationmark.triangle.fill")
        case "warning":
            return (.spectreWarning, "exclamationmark.circle.fill")
        case "healthy":
            return (.spectreSuccess, "checkmark.circle.fill")
        default:
            return (.spectrePrimary, "checkmark.seal.fill")
        }
    }

    private var deltaView: some View {
        let isPositive = site.deltaPct > 0
        return HStack(spacing: 2) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.caption2)
            Text("\(String(format: "%.1f", abs(site.deltaPct)))%")
                .font(.caption2)
        }
        .foregroundColor(isPositive ? .spectreSuccess : .spectreDestructive)
    }
}

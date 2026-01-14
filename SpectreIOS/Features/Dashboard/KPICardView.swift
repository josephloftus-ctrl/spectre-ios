import SwiftUI

struct KPICardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: SpectreTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.spectreText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundColor(.spectreTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SpectreTheme.Spacing.md)
        .background(SpectreTheme.cardBackground)
        .cornerRadius(SpectreTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: SpectreTheme.Radius.lg)
                .stroke(SpectreTheme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: SpectreTheme.cardShadow, radius: 6, x: 0, y: 3)
    }
}

import SwiftUI

struct KPICardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: SteadyTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.steadyText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption)
                .foregroundColor(.steadyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SteadyTheme.Spacing.md)
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.lg)
                .stroke(SteadyTheme.borderSubtle, lineWidth: 1)
        )
        .shadow(color: SteadyTheme.cardShadow, radius: 6, x: 0, y: 3)
    }
}

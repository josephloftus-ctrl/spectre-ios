import SwiftUI

struct CountItemRow: View {
    let zoneItem: ZCZoneItem
    let currentCount: Double?
    let lastCount: Double?
    let isSkipped: Bool
    let varianceStatus: VarianceStatus

    let onIncrement: () -> Void
    let onDecrement: () -> Void
    let onTapCount: () -> Void
    let onSwipeSkip: () -> Void
    let onLongPress: () -> Void

    @State private var offset: CGFloat = 0

    private var item: ZCItem? {
        zoneItem.item
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Skip action background
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                    Text("Skip")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.steadyTextTertiary)

            // Main content
            mainContent
                .offset(x: offset)
                .gesture(swipeGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: SteadyTheme.Radius.md))
    }

    private var mainContent: some View {
        HStack(spacing: SteadyTheme.Spacing.md) {
            // Status indicator
            statusIndicator

            // Item info
            VStack(alignment: .leading, spacing: 4) {
                Text(item?.name ?? "Unknown Item")
                    .font(.body.weight(.medium))
                    .foregroundColor(isSkipped ? .steadyTextTertiary : .steadyText)
                    .strikethrough(isSkipped)

                HStack(spacing: SteadyTheme.Spacing.sm) {
                    // Unit
                    Text(item?.unit ?? "")
                        .font(.caption)
                        .foregroundColor(.steadyTextSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(SteadyTheme.secondaryBackground)
                        .cornerRadius(4)

                    // Par level
                    if let par = zoneItem.parLevel {
                        Text("Par: \(Int(par))")
                            .font(.caption)
                            .foregroundColor(.steadyTextSecondary)
                    }

                    // Last count
                    if let last = lastCount {
                        Text("Last: \(Int(last))")
                            .font(.caption)
                            .foregroundColor(.steadyTextTertiary)
                    }
                }
            }

            Spacer()

            // Count controls
            if !isSkipped {
                countControls
            } else {
                Text("Skipped")
                    .font(.caption)
                    .foregroundColor(.steadyTextTertiary)
                    .italic()
            }
        }
        .padding(SteadyTheme.Spacing.md)
        .background(SteadyTheme.cardBackground)
        .contentShape(Rectangle())
        .onLongPressGesture {
            onLongPress()
        }
    }

    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
    }

    private var statusColor: Color {
        if isSkipped {
            return .steadyTextTertiary
        }

        guard currentCount != nil else {
            return .steadyWarning  // Uncounted
        }

        switch varianceStatus {
        case .critical: return .steadyDestructive
        case .warning: return .steadyWarning
        case .good: return .steadySuccess
        case .unknown: return .steadyTextSecondary
        }
    }

    private var countControls: some View {
        HStack(spacing: SteadyTheme.Spacing.sm) {
            // Decrement button
            Button(action: onDecrement) {
                Image(systemName: "minus")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.steadyText)
                    .frame(width: 36, height: 36)
                    .background(SteadyTheme.secondaryBackground)
                    .clipShape(Circle())
            }
            .disabled(currentCount == nil || currentCount == 0)
            .opacity(currentCount == nil || currentCount == 0 ? 0.5 : 1)

            // Count display (tappable)
            Button(action: onTapCount) {
                Text(countDisplay)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundColor(currentCount != nil ? .steadyText : .steadyTextTertiary)
                    .frame(width: 50)
                    .padding(.vertical, 8)
                    .background(SteadyTheme.tertiaryBackground)
                    .cornerRadius(SteadyTheme.Radius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: SteadyTheme.Radius.sm)
                            .stroke(
                                currentCount == nil ? SteadyTheme.warning.opacity(0.5) : SteadyTheme.borderSubtle,
                                lineWidth: 1
                            )
                    )
            }

            // Increment button
            Button(action: onIncrement) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.steadyText)
                    .frame(width: 36, height: 36)
                    .background(SteadyTheme.primary)
                    .clipShape(Circle())
            }
        }
    }

    private var countDisplay: String {
        if let count = currentCount {
            if count.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(count))"
            }
            return String(format: "%.1f", count)
        }
        return "--"
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.width < 0 {
                    offset = max(value.translation.width, -100)
                }
            }
            .onEnded { value in
                if value.translation.width < -60 {
                    // Trigger skip
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                    }
                    onSwipeSkip()
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        offset = 0
                    }
                }
            }
    }
}

#Preview {
    ZStack {
        Color.steadyBackground.ignoresSafeArea()

        VStack(spacing: 8) {
            // Preview with mock data would go here
            Text("CountItemRow Preview")
                .foregroundColor(.steadyText)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}

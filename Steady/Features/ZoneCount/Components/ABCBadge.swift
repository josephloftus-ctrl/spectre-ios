import SwiftUI

/// Badge displaying ABC inventory classification
/// A = High value (red), B = Medium value (orange), C = Low value (gray)
struct ABCBadge: View {
    let classification: String?

    var body: some View {
        if let cls = classification?.uppercased(), ["A", "B", "C"].contains(cls) {
            Text(cls)
                .font(.caption2.bold())
                .frame(width: 20, height: 20)
                .background(backgroundColor)
                .foregroundColor(.white)
                .clipShape(Circle())
        }
    }

    private var backgroundColor: Color {
        switch classification?.uppercased() {
        case "A":
            return .red.opacity(0.85)
        case "B":
            return .orange.opacity(0.85)
        case "C":
            return .gray.opacity(0.6)
        default:
            return .clear
        }
    }
}

/// Extended badge with tooltip showing full classification
struct ABCBadgeWithInfo: View {
    let abcClass: String?
    let xyzClass: String?
    let showTooltip: Bool

    @State private var showingInfo = false

    var body: some View {
        Button(action: { showingInfo.toggle() }) {
            ABCBadge(classification: abcClass)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showingInfo) {
            VStack(alignment: .leading, spacing: 8) {
                if let abc = abcClass {
                    HStack {
                        ABCBadge(classification: abc)
                        Text(abcDescription)
                            .font(.caption)
                    }
                }
                if let xyz = xyzClass {
                    Text("Variability: \(xyzDescription)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }

    private var abcDescription: String {
        switch abcClass?.uppercased() {
        case "A": return "High value item (top 80%)"
        case "B": return "Medium value item (next 15%)"
        case "C": return "Low value item (bottom 5%)"
        default: return "Unclassified"
        }
    }

    private var xyzDescription: String {
        switch xyzClass?.uppercased() {
        case "X": return "Stable demand"
        case "Y": return "Moderate variability"
        case "Z": return "Unpredictable demand"
        default: return "Unknown"
        }
    }
}

#Preview {
    ZStack {
        Color.steadyBackground.ignoresSafeArea()

        VStack(spacing: 20) {
            HStack(spacing: 16) {
                ABCBadge(classification: "A")
                ABCBadge(classification: "B")
                ABCBadge(classification: "C")
                ABCBadge(classification: nil)
            }

            HStack(spacing: 16) {
                ABCBadgeWithInfo(abcClass: "A", xyzClass: "X", showTooltip: true)
                ABCBadgeWithInfo(abcClass: "B", xyzClass: "Y", showTooltip: true)
                ABCBadgeWithInfo(abcClass: "C", xyzClass: "Z", showTooltip: true)
            }
        }
    }
    .preferredColorScheme(.dark)
}

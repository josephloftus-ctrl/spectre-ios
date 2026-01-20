import SwiftUI

struct QuantityInputSheet: View {
    let itemName: String
    let unit: String
    let parLevel: Double?
    let lastCount: Double?
    @Binding var quantity: Double?
    let onDone: () -> Void

    @State private var inputText = ""
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: SteadyTheme.Spacing.lg) {
            // Header
            VStack(spacing: SteadyTheme.Spacing.sm) {
                Text(itemName)
                    .font(.headline)
                    .foregroundColor(.steadyText)

                HStack(spacing: SteadyTheme.Spacing.md) {
                    if let par = parLevel {
                        Label("Par: \(Int(par))", systemImage: "target")
                            .font(.caption)
                            .foregroundColor(.steadyTextSecondary)
                    }
                    if let last = lastCount {
                        Label("Last: \(Int(last))", systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.steadyTextTertiary)
                    }
                }
            }
            .padding(.top, SteadyTheme.Spacing.md)

            // Large display
            VStack(spacing: SteadyTheme.Spacing.xs) {
                Text(inputText.isEmpty ? "0" : inputText)
                    .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.steadyText)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(.title3)
                    .foregroundColor(.steadyTextSecondary)
            }
            .padding(.vertical, SteadyTheme.Spacing.lg)

            // Numpad
            numpad

            Spacer()

            // Done button
            Button(action: {
                if let value = Double(inputText) {
                    quantity = value
                } else if inputText.isEmpty {
                    quantity = 0
                }
                onDone()
            }) {
                Text("Done")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, SteadyTheme.Spacing.md)
            }
            .buttonStyle(SteadyPrimaryButtonStyle(isFullWidth: true))
            .padding(.bottom, SteadyTheme.Spacing.lg)
        }
        .padding(.horizontal, SteadyTheme.Spacing.lg)
        .background(SteadyTheme.background)
        .onAppear {
            if let q = quantity {
                if q.truncatingRemainder(dividingBy: 1) == 0 {
                    inputText = "\(Int(q))"
                } else {
                    inputText = String(format: "%.1f", q)
                }
            }
        }
    }

    private var numpad: some View {
        VStack(spacing: SteadyTheme.Spacing.sm) {
            ForEach(numpadRows, id: \.self) { row in
                HStack(spacing: SteadyTheme.Spacing.sm) {
                    ForEach(row, id: \.self) { key in
                        numpadButton(key)
                    }
                }
            }
        }
    }

    private var numpadRows: [[String]] {
        [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            [".", "0", "⌫"]
        ]
    }

    private func numpadButton(_ key: String) -> some View {
        Button {
            handleKey(key)
        } label: {
            Text(key)
                .font(.title2.weight(.medium))
                .foregroundColor(key == "⌫" ? .steadyTextSecondary : .steadyText)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(
                    key == "⌫"
                        ? SteadyTheme.secondaryBackground
                        : SteadyTheme.cardBackground
                )
                .cornerRadius(SteadyTheme.Radius.md)
        }
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            if !inputText.isEmpty {
                inputText.removeLast()
            }
        case ".":
            if !inputText.contains(".") {
                inputText += inputText.isEmpty ? "0." : "."
            }
        default:
            // Limit to reasonable quantity
            if inputText.count < 6 {
                inputText += key
            }
        }
    }
}

#Preview {
    QuantityInputSheet(
        itemName: "Chicken Breast, raw",
        unit: "case",
        parLevel: 4,
        lastCount: 3,
        quantity: .constant(nil),
        onDone: {}
    )
    .preferredColorScheme(.dark)
}

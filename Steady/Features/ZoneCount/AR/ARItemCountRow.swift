import SwiftUI

/// Row for counting an item in the AR overlay
struct ARItemCountRow: View {
    let zoneItem: ZCZoneItem
    let session: ZCCountSession

    @State private var quantity: Double?
    @State private var showingNumpad = false

    private var item: ZCItem? {
        zoneItem.item
    }

    private var expected: Double {
        zoneItem.parLevel ?? 0
    }

    private var variance: Double? {
        guard let qty = quantity else { return nil }
        return qty - expected
    }

    private var varianceStatus: VarianceStatus {
        guard let qty = quantity else { return .unknown }
        return zoneItem.varianceStatus(quantity: qty)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            // Item info
            VStack(alignment: .leading, spacing: 2) {
                Text(item?.name ?? "Unknown")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)

                HStack(spacing: 8) {
                    // Expected
                    Label("Par: \(Int(expected))", systemImage: "target")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))

                    // Variance
                    if let v = variance {
                        varianceLabel(v)
                    }
                }
            }

            Spacer()

            // Count controls
            HStack(spacing: 8) {
                // Decrement
                Button {
                    if let q = quantity, q > 0 {
                        quantity = q - 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(quantity ?? 0 > 0 ? 0.9 : 0.3))
                }
                .disabled(quantity == nil || quantity == 0)

                // Quantity display (tap for numpad)
                Button {
                    showingNumpad = true
                } label: {
                    Text(quantityText)
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundColor(quantity != nil ? .white : .white.opacity(0.4))
                        .frame(width: 50)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(borderColor, lineWidth: 1)
                                )
                        )
                }

                // Increment
                Button {
                    quantity = (quantity ?? 0) + 1
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
        .sheet(isPresented: $showingNumpad) {
            ARNumpadSheet(
                itemName: item?.name ?? "Item",
                unit: item?.unit ?? "",
                expected: expected,
                quantity: $quantity
            )
            .presentationDetents([.medium])
        }
    }

    private var quantityText: String {
        if let q = quantity {
            return q.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(q))" : String(format: "%.1f", q)
        }
        return "--"
    }

    private var statusColor: Color {
        switch varianceStatus {
        case .critical: return .red
        case .warning: return .yellow
        case .good: return .green
        case .unknown: return .gray
        }
    }

    private var borderColor: Color {
        if quantity == nil {
            return .orange.opacity(0.5)
        }
        return .white.opacity(0.2)
    }

    @ViewBuilder
    private func varianceLabel(_ v: Double) -> some View {
        let sign = v >= 0 ? "+" : ""
        let color: Color = v < 0 ? .red : (v > 0 ? .green : .white.opacity(0.6))

        Text("\(sign)\(Int(v))")
            .font(.caption2.weight(.medium))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .clipShape(Capsule())
    }
}

/// Numpad sheet for AR quantity entry
struct ARNumpadSheet: View {
    let itemName: String
    let unit: String
    let expected: Double
    @Binding var quantity: Double?

    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text(itemName)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    Label("Par: \(Int(expected))", systemImage: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top)

            // Display
            VStack(spacing: 4) {
                Text(inputText.isEmpty ? "0" : inputText)
                    .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical)

            // Numpad
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"], id: \.self) { key in
                    Button {
                        handleKey(key)
                    } label: {
                        Text(key)
                            .font(.title2.weight(.medium))
                            .foregroundColor(key == "⌫" ? .secondary : .primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)

            // Done button
            Button {
                if let value = Double(inputText) {
                    quantity = value
                } else if inputText.isEmpty {
                    quantity = 0
                }
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            if let q = quantity {
                inputText = q.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(q))" : String(format: "%.1f", q)
            }
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
            if inputText.count < 6 {
                inputText += key
            }
        }
    }
}

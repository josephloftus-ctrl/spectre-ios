import SwiftUI

struct ItemRowView: View {
    @Bindable var item: InventoryItem
    @State private var showNumpad = false
    @State private var dragOffset: CGFloat = 0

    private let swipeThreshold: CGFloat = 50

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemDescription)
                    .font(.body)
                    .lineLimit(2)

                Text(item.distNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.uom)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40)

            HStack(spacing: 12) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.secondary)
                    .opacity(dragOffset < -20 ? 1 : 0.3)

                Text("\(item.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(minWidth: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showNumpad = true
                    }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .opacity(dragOffset > 20 ? 1 : 0.3)
            }

            if item.isCounted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(item.isCounted ? Color(.systemBackground) : Color(.systemGray6))
        .opacity(item.isCounted ? 0.7 : 1.0)
        .contentShape(Rectangle())
        .offset(x: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 20, coordinateSpace: .local)
                .onChanged { value in
                    // Only allow horizontal swipes, ignore vertical (for scrolling)
                    if abs(value.translation.width) > abs(value.translation.height) {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3)) {
                        if value.translation.width > swipeThreshold {
                            incrementCount()
                        } else if value.translation.width < -swipeThreshold {
                            decrementCount()
                        }
                        dragOffset = 0
                    }
                }
        )
        .sheet(isPresented: $showNumpad) {
            NumpadView(count: $item.count) {
                markCounted()
            }
            .presentationDetents([.height(350)])
        }
    }

    private func incrementCount() {
        item.count += 1
        markCounted()
    }

    private func decrementCount() {
        if item.count > 0 {
            item.count -= 1
        }
        markCounted()
    }

    private func markCounted() {
        if !item.isCounted {
            item.isCounted = true
            item.countedAt = Date()
        }
    }
}

struct NumpadView: View {
    @Binding var count: Int
    @Environment(\.dismiss) private var dismiss
    var onSave: () -> Void

    @State private var inputString = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter Count")
                .font(.headline)

            Text(inputString.isEmpty ? "0" : inputString)
                .font(.system(size: 48, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { num in
                    NumpadButton(title: "\(num)") {
                        inputString += "\(num)"
                    }
                }

                NumpadButton(title: "C", color: .red) {
                    inputString = ""
                }

                NumpadButton(title: "0") {
                    inputString += "0"
                }

                NumpadButton(title: "OK", color: .green) {
                    count = Int(inputString) ?? 0
                    onSave()
                    dismiss()
                }
            }
        }
        .padding()
        .onAppear {
            inputString = count > 0 ? "\(count)" : ""
        }
    }
}

struct NumpadButton: View {
    let title: String
    var color: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

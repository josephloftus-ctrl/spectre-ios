import SwiftUI
import SwiftData

struct ZoneCountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let zone: ZCZone
    let session: ZCCountSession

    @State private var viewModel = ZoneCountViewModel()
    @State private var selectedItem: ZCZoneItem?
    @State private var showingQuantityInput = false
    @State private var showingNoteInput = false
    @State private var noteText = ""
    @State private var showingConfirmSubmit = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.steadyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with zone info
                zoneHeader

                // Item list
                itemList

                // Bottom bar with progress
                bottomBar
            }
        }
        .navigationTitle(zone.code)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.steadyTextSecondary)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    if viewModel.isComplete {
                        submitAndDismiss()
                    } else {
                        showingConfirmSubmit = true
                    }
                }
                .font(.body.weight(.semibold))
                .foregroundColor(.steadyPrimary)
            }
        }
        .toolbarBackground(SteadyTheme.cardBackground, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            viewModel.configure(zone: zone, session: session, modelContext: modelContext)
        }
        .sheet(isPresented: $showingQuantityInput) {
            if let item = selectedItem {
                QuantityInputSheet(
                    itemName: item.item?.name ?? "Item",
                    unit: item.item?.unit ?? "",
                    parLevel: item.parLevel,
                    lastCount: viewModel.lastCount(for: item),
                    quantity: Binding(
                        get: { viewModel.count(for: item) },
                        set: { newValue in
                            if let value = newValue {
                                viewModel.setCount(value, for: item)
                            }
                        }
                    ),
                    onDone: {
                        showingQuantityInput = false
                        selectedItem = nil
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingNoteInput) {
            noteInputSheet
        }
        .alert("Submit Incomplete Count?", isPresented: $showingConfirmSubmit) {
            Button("Cancel", role: .cancel) {}
            Button("Submit Anyway") {
                submitAndDismiss()
            }
        } message: {
            Text("\(viewModel.remainingCount) items haven't been counted yet. Do you want to submit anyway?")
        }
    }

    // MARK: - Zone Header

    private var zoneHeader: some View {
        VStack(spacing: SteadyTheme.Spacing.sm) {
            HStack {
                // Zone type icon
                Image(systemName: zone.zoneType.icon)
                    .font(.title2)
                    .foregroundColor(zone.zoneType.iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(zone.name)
                        .font(.headline)
                        .foregroundColor(.steadyText)

                    if let shelfPosition = getShelfPosition() {
                        Text(shelfPosition)
                            .font(.caption)
                            .foregroundColor(.steadyTextTertiary)
                    }
                }

                Spacer()

                // Timer
                VStack(alignment: .trailing) {
                    Text(viewModel.durationDisplay)
                        .font(.title3.monospacedDigit())
                        .foregroundColor(.steadyTextSecondary)
                    Text("elapsed")
                        .font(.caption2)
                        .foregroundColor(.steadyTextTertiary)
                }
            }
        }
        .padding(SteadyTheme.Spacing.md)
        .background(SteadyTheme.cardBackground)
    }

    // MARK: - Item List

    private var itemList: some View {
        ScrollView {
            LazyVStack(spacing: SteadyTheme.Spacing.sm) {
                ForEach(viewModel.sortedItems, id: \.id) { zoneItem in
                    CountItemRow(
                        zoneItem: zoneItem,
                        currentCount: viewModel.count(for: zoneItem),
                        lastCount: viewModel.lastCount(for: zoneItem),
                        isSkipped: viewModel.isSkipped(zoneItem),
                        varianceStatus: viewModel.varianceStatus(for: zoneItem),
                        onIncrement: { viewModel.increment(for: zoneItem) },
                        onDecrement: { viewModel.decrement(for: zoneItem) },
                        onTapCount: {
                            selectedItem = zoneItem
                            showingQuantityInput = true
                        },
                        onSwipeSkip: { viewModel.skip(item: zoneItem) },
                        onLongPress: {
                            selectedItem = zoneItem
                            noteText = viewModel.note(for: zoneItem) ?? ""
                            showingNoteInput = true
                        }
                    )
                }
            }
            .padding(SteadyTheme.Spacing.md)
            .padding(.bottom, 100)  // Space for bottom bar
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: SteadyTheme.Spacing.sm) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(SteadyTheme.secondaryBackground)

                    Rectangle()
                        .fill(viewModel.isComplete ? SteadyTheme.success : SteadyTheme.primary)
                        .frame(width: geo.size.width * viewModel.progress)
                        .animation(.spring(response: 0.3), value: viewModel.progress)
                }
            }
            .frame(height: 4)

            // Progress text
            HStack {
                Text("Progress: \(viewModel.countedItemCount)/\(viewModel.totalItemCount) items")
                    .font(.subheadline)
                    .foregroundColor(.steadyTextSecondary)

                Spacer()

                if viewModel.isComplete {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.steadySuccess)
                } else {
                    Text("\(viewModel.remainingCount) remaining")
                        .font(.subheadline)
                        .foregroundColor(.steadyWarning)
                }
            }
            .padding(.horizontal, SteadyTheme.Spacing.md)
            .padding(.bottom, SteadyTheme.Spacing.sm)
        }
        .padding(.top, SteadyTheme.Spacing.sm)
        .background(SteadyTheme.cardBackground)
    }

    // MARK: - Note Input Sheet

    private var noteInputSheet: some View {
        NavigationStack {
            VStack(spacing: SteadyTheme.Spacing.lg) {
                // Quick note buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: SteadyTheme.Spacing.sm) {
                        ForEach(CountNote.allCases) { note in
                            Button {
                                noteText = note.rawValue
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: note.icon)
                                    Text(note.displayName)
                                }
                                .font(.caption)
                                .foregroundColor(noteText == note.rawValue ? .white : .steadyTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    noteText == note.rawValue
                                        ? SteadyTheme.primary
                                        : SteadyTheme.secondaryBackground
                                )
                                .cornerRadius(SteadyTheme.Radius.full)
                            }
                        }
                    }
                    .padding(.horizontal, SteadyTheme.Spacing.md)
                }

                // Custom note input
                TextField("Custom note...", text: $noteText)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(SteadyTheme.secondaryBackground)
                    .cornerRadius(SteadyTheme.Radius.md)
                    .padding(.horizontal, SteadyTheme.Spacing.md)

                Spacer()
            }
            .padding(.top, SteadyTheme.Spacing.md)
            .background(SteadyTheme.background)
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingNoteInput = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let item = selectedItem {
                            viewModel.setNote(noteText, for: item)
                        }
                        showingNoteInput = false
                    }
                    .font(.body.weight(.semibold))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Helpers

    private func getShelfPosition() -> String? {
        // Get shelf position from canon template if available
        for template in Canon.zoneTemplates where template.zoneType == zone.zoneType {
            if zone.name.contains(template.subType) {
                return template.shelfPosition
            }
        }
        return nil
    }

    private func submitAndDismiss() {
        viewModel.submitZone()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        // Preview requires mock data
        Text("ZoneCountView Preview")
            .foregroundColor(.steadyText)
    }
    .preferredColorScheme(.dark)
}

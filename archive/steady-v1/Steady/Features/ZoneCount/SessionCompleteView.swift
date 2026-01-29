import SwiftUI

struct SessionCompleteView: View {
    let session: ZCCountSession

    @Environment(\.dismiss) private var dismiss
    @State private var showingExportOptions = false

    var body: some View {
        ZStack {
            Color.steadyBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: SteadyTheme.Spacing.xl) {
                    // Success header
                    successHeader

                    // Session info
                    sessionInfo

                    // Variance summary
                    varianceSummary

                    // Action buttons
                    actionButtons
                }
                .padding(SteadyTheme.Spacing.lg)
            }
        }
        .navigationTitle("Count Complete")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .font(.body.weight(.semibold))
            }
        }
        .sheet(isPresented: $showingExportOptions) {
            exportSheet
        }
    }

    // MARK: - Success Header

    private var successHeader: some View {
        VStack(spacing: SteadyTheme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.steadySuccess)

            Text("COUNT COMPLETE")
                .font(.title2.weight(.bold))
                .foregroundColor(.steadyText)
        }
        .padding(.top, SteadyTheme.Spacing.lg)
    }

    // MARK: - Session Info

    private var sessionInfo: some View {
        SteadyCard {
            VStack(spacing: SteadyTheme.Spacing.md) {
                // Site name
                if let siteName = session.site?.name {
                    Text(siteName)
                        .font(.headline)
                        .foregroundColor(.steadyText)
                }

                // Date and time
                HStack {
                    Text(session.startedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.steadyTextSecondary)

                    if let countedBy = session.countedBy {
                        Text("•")
                            .foregroundColor(.steadyTextTertiary)
                        Text("Counted by: \(countedBy)")
                            .font(.subheadline)
                            .foregroundColor(.steadyTextSecondary)
                    }
                }

                Divider()
                    .background(SteadyTheme.border)

                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: SteadyTheme.Spacing.md) {
                    statItem(
                        label: "Zones Counted",
                        value: "\(session.zonesCountedCount)/\(session.totalZonesCount)"
                    )

                    statItem(
                        label: "Items Counted",
                        value: "\(session.itemsCountedCount)/\(session.totalItemsCount)"
                    )

                    statItem(
                        label: "Items Skipped",
                        value: "\(session.skippedItemsCount)"
                    )

                    statItem(
                        label: "Duration",
                        value: session.durationDisplay
                    )
                }
            }
        }
    }

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundColor(.steadyText)

            Text(label)
                .font(.caption)
                .foregroundColor(.steadyTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Variance Summary

    private var varianceSummary: some View {
        SteadyCard {
            VStack(alignment: .leading, spacing: SteadyTheme.Spacing.md) {
                Text("VARIANCE SUMMARY")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.steadyTextTertiary)

                HStack(spacing: SteadyTheme.Spacing.lg) {
                    // Under par
                    HStack(spacing: SteadyTheme.Spacing.sm) {
                        Circle()
                            .fill(Color.steadyDestructive)
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading) {
                            Text("\(session.underParCount)")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.steadyText)
                            Text("Under par")
                                .font(.caption)
                                .foregroundColor(.steadyTextSecondary)
                        }
                    }

                    Spacer()

                    // At/above par
                    HStack(spacing: SteadyTheme.Spacing.sm) {
                        Circle()
                            .fill(Color.steadySuccess)
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading) {
                            Text("\(session.atOrAboveParCount)")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.steadyText)
                            Text("At/above par")
                                .font(.caption)
                                .foregroundColor(.steadyTextSecondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: SteadyTheme.Spacing.md) {
            Button {
                showingExportOptions = true
            } label: {
                Label("Export CSV", systemImage: "square.and.arrow.up")
                    .font(.body.weight(.medium))
            }
            .buttonStyle(SteadySecondaryButtonStyle())

            Button {
                // TODO: Show details view
            } label: {
                Label("View Details", systemImage: "list.bullet")
                    .font(.body.weight(.medium))
            }
            .buttonStyle(SteadySecondaryButtonStyle())
        }
    }

    // MARK: - Export Sheet

    private var exportSheet: some View {
        NavigationStack {
            VStack(spacing: SteadyTheme.Spacing.lg) {
                Text("Export Options")
                    .font(.headline)
                    .foregroundColor(.steadyText)

                VStack(spacing: SteadyTheme.Spacing.sm) {
                    exportOption(
                        icon: "doc.text",
                        title: "Download CSV",
                        description: "Save file to device"
                    ) {
                        exportCSV()
                    }

                    exportOption(
                        icon: "square.and.arrow.up",
                        title: "Share",
                        description: "Send via email, AirDrop, etc."
                    ) {
                        shareCSV()
                    }

                    exportOption(
                        icon: "doc.on.clipboard",
                        title: "Copy to Clipboard",
                        description: "For quick paste into spreadsheets"
                    ) {
                        copyToClipboard()
                    }
                }

                Spacer()
            }
            .padding(SteadyTheme.Spacing.lg)
            .background(SteadyTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingExportOptions = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func exportOption(
        icon: String,
        title: String,
        description: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: SteadyTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.steadyPrimary)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundColor(.steadyText)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.steadyTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.steadyTextTertiary)
            }
            .padding(SteadyTheme.Spacing.md)
            .background(SteadyTheme.cardBackground)
            .cornerRadius(SteadyTheme.Radius.md)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Export Actions

    private func generateCSV() -> String {
        var csv = "session_id,site_name,zone_code,zone_name,item_name,unit,quantity,par_level,variance,timestamp,counted_by,note\n"

        for entry in session.entries {
            let siteName = session.site?.name ?? ""
            let zoneCode = entry.zone?.code ?? ""
            let zoneName = entry.zone?.name ?? ""
            let itemName = entry.item?.name ?? ""
            let unit = entry.item?.unit ?? ""
            let parLevel = entry.zoneItem?.parLevel ?? 0
            let variance = entry.variance ?? 0
            let countedBy = session.countedBy ?? ""
            let note = entry.note ?? ""

            csv += "\"\(session.id)\",\"\(siteName)\",\"\(zoneCode)\",\"\(zoneName)\",\"\(itemName)\",\"\(unit)\",\(entry.quantity),\(parLevel),\(variance),\"\(entry.timestamp.ISO8601Format())\",\"\(countedBy)\",\"\(note)\"\n"
        }

        return csv
    }

    private func exportCSV() {
        let csv = generateCSV()
        // Save to files app
        // Implementation would use UIDocumentPickerViewController or similar
        showingExportOptions = false
    }

    private func shareCSV() {
        let csv = generateCSV()
        // Share using UIActivityViewController
        // Implementation would create a temp file and share
        showingExportOptions = false
    }

    private func copyToClipboard() {
        let csv = generateCSV()
        UIPasteboard.general.string = csv
        showingExportOptions = false
    }
}

#Preview {
    NavigationStack {
        Text("SessionCompleteView Preview")
            .foregroundColor(.steadyText)
    }
    .preferredColorScheme(.dark)
}

import SwiftUI

struct SiteDetailView: View {
    @EnvironmentObject var api: SteadyAPI
    @State private var siteDetail: SiteDetail?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab = 0

    let site: SiteSummary

    var body: some View {
        ZStack {
            Color.steadyBackground.ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let detail = siteDetail {
                ScrollView {
                    VStack(spacing: SteadyTheme.Spacing.md) {
                        headerSection(detail)
                        metricsSection(detail)
                        tabSection(detail)
                    }
                    .padding()
                }
            } else {
                errorView
            }
        }
        .navigationTitle(site.site)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SteadyTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await loadSiteDetail()
        }
        .refreshable {
            await loadSiteDetail()
        }
    }

    private func headerSection(_ detail: SiteDetail) -> some View {
        VStack(spacing: SteadyTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.siteName)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.steadyText)

                    Text("Last updated: \(detail.lastUpdated)")
                        .font(.caption)
                        .foregroundColor(.steadyTextSecondary)
                }
                Spacer()
                healthBadge(detail.healthStatus, score: detail.healthScore)
            }
        }
        .padding()
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.lg)
    }

    private func metricsSection(_ detail: SiteDetail) -> some View {
        HStack(spacing: SteadyTheme.Spacing.sm) {
            metricCard(
                title: "Total Value",
                value: formatCurrency(detail.totalValue),
                change: detail.valueChange,
                icon: "dollarsign.circle.fill",
                color: .steadySuccess
            )

            metricCard(
                title: "Item Count",
                value: "\(detail.itemCount)",
                change: nil,
                icon: "shippingbox.fill",
                color: .steadyPrimary
            )

            metricCard(
                title: "Flags",
                value: "\(detail.flagCount)",
                change: nil,
                icon: "flag.fill",
                color: detail.flagCount > 0 ? .steadyWarning : .steadySuccess
            )
        }
    }

    private func metricCard(title: String, value: String, change: Double?, icon: String, color: Color) -> some View {
        VStack(spacing: SteadyTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .foregroundColor(.steadyText)

            Text(title)
                .font(.caption2)
                .foregroundColor(.steadyTextSecondary)

            if let change = change {
                HStack(spacing: 2) {
                    Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text("\(String(format: "%.1f", abs(change)))%")
                        .font(.caption2)
                }
                .foregroundColor(change >= 0 ? .steadySuccess : .steadyDestructive)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SteadyTheme.Spacing.md)
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.md)
    }

    private func tabSection(_ detail: SiteDetail) -> some View {
        VStack(spacing: SteadyTheme.Spacing.sm) {
            Picker("View", selection: $selectedTab) {
                Text("Flags").tag(0)
                Text("Rooms").tag(1)
                Text("Items").tag(2)
            }
            .pickerStyle(.segmented)

            switch selectedTab {
            case 0:
                flagsTab(detail.flags)
            case 1:
                roomsTab(detail.rooms)
            case 2:
                itemsTab(detail.items)
            default:
                EmptyView()
            }
        }
    }

    private func flagsTab(_ flags: [ItemFlag]) -> some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            if flags.isEmpty {
                emptyState(icon: "checkmark.circle", message: "No flags - looking good!")
            } else {
                ForEach(flags) { flag in
                    FlagRowView(flag: flag)
                }
            }
        }
    }

    private func roomsTab(_ rooms: [RoomSummary]) -> some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            if rooms.isEmpty {
                emptyState(icon: "square.grid.2x2", message: "No rooms configured")
            } else {
                ForEach(rooms) { room in
                    RoomRowView(room: room)
                }
            }
        }
    }

    private func itemsTab(_ items: [InventoryItemSummary]) -> some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            if items.isEmpty {
                emptyState(icon: "shippingbox", message: "No items found")
            } else {
                ForEach(items.prefix(50)) { item in
                    ItemRowView(item: item)
                }
                if items.count > 50 {
                    Text("+ \(items.count - 50) more items")
                        .font(.caption)
                        .foregroundColor(.steadyTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
        }
    }

    private func emptyState(icon: String, message: String) -> some View {
        VStack(spacing: SteadyTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.steadyTextTertiary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.steadyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SteadyTheme.Spacing.xl)
    }

    private var errorView: some View {
        VStack(spacing: SteadyTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.steadyWarning)
            Text(errorMessage ?? "Failed to load site details")
                .foregroundColor(.steadyTextSecondary)
            Button("Retry") {
                Task { await loadSiteDetail() }
            }
            .steadyPrimaryButton()
        }
    }

    private func healthBadge(_ status: String, score: Int) -> some View {
        let (color, icon) = statusColorAndIcon(status)
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text("\(score)")
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(SteadyTheme.Radius.full)
    }

    private func statusColorAndIcon(_ status: String) -> (Color, String) {
        switch status.lowercased() {
        case "critical":
            return (.steadyDestructive, "exclamationmark.triangle.fill")
        case "warning":
            return (.steadyWarning, "exclamationmark.circle.fill")
        case "healthy":
            return (.steadySuccess, "checkmark.circle.fill")
        default:
            return (.steadyPrimary, "checkmark.seal.fill")
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private func loadSiteDetail() async {
        isLoading = true
        errorMessage = nil
        do {
            siteDetail = try await api.fetchSiteDetail(siteId: site.site)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

// MARK: - Supporting Views

struct FlagRowView: View {
    let flag: ItemFlag

    var flagColor: Color {
        switch flag.severity.lowercased() {
        case "high", "critical":
            return .steadyDestructive
        case "medium", "warning":
            return .steadyWarning
        default:
            return .steadyInfo
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(flag.itemName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.steadyText)

                Text(flag.reason)
                    .font(.caption)
                    .foregroundColor(.steadyTextSecondary)

                if let location = flag.location {
                    Text(location)
                        .font(.caption2)
                        .foregroundColor(.steadyTextTertiary)
                }
            }

            Spacer()

            Text(flag.flagType)
                .font(.caption2.weight(.medium))
                .foregroundColor(flagColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(flagColor.opacity(0.15))
                .cornerRadius(SteadyTheme.Radius.sm)
        }
        .padding()
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.md)
    }
}

struct RoomRowView: View {
    let room: RoomSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(room.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.steadyText)

                Text("\(room.itemCount) items")
                    .font(.caption)
                    .foregroundColor(.steadyTextSecondary)
            }

            Spacer()

            Text(formatCurrency(room.totalValue))
                .font(.subheadline)
                .foregroundColor(.steadyTextSecondary)
        }
        .padding()
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.md)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

struct ItemRowView: View {
    let item: InventoryItemSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.steadyText)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(item.sku)
                        .font(.caption)
                        .foregroundColor(.steadyTextTertiary)

                    if let location = item.location {
                        Text(location)
                            .font(.caption)
                            .foregroundColor(.steadyTextTertiary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", item.quantity)) \(item.uom)")
                    .font(.caption)
                    .foregroundColor(.steadyTextSecondary)

                Text(formatCurrency(item.value))
                    .font(.caption.weight(.medium))
                    .foregroundColor(.steadyText)
            }
        }
        .padding(.vertical, SteadyTheme.Spacing.sm)
        .padding(.horizontal, SteadyTheme.Spacing.md)
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.sm)
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

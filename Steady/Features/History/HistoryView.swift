import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var api: SteadyAPI
    @State private var history: HistoryResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.steadyBackground.ignoresSafeArea()

            if isLoading {
                ProgressView()
            } else if let history = history {
                historyContent(history)
            } else {
                errorView
            }
        }
        .navigationTitle("Trends & History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(SteadyTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await loadHistory()
        }
        .refreshable {
            await loadHistory()
        }
    }

    private func historyContent(_ history: HistoryResponse) -> some View {
        ScrollView {
            VStack(spacing: SteadyTheme.Spacing.md) {
                if let trends = history.trends {
                    trendsSection(trends)
                }

                snapshotsSection(history.snapshots)

                if let trends = history.trends, !trends.movers.isEmpty {
                    moversSection(trends.movers)
                }
            }
            .padding()
        }
    }

    private func trendsSection(_ trends: TrendData) -> some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            Text("This Week")
                .font(.headline)
                .foregroundColor(.steadyText)

            HStack(spacing: SteadyTheme.Spacing.sm) {
                trendCard(
                    title: "Value",
                    value: formatCurrency(trends.valueChange),
                    percent: trends.valueChangePercent,
                    icon: "dollarsign.circle"
                )

                trendCard(
                    title: "Flags",
                    value: "\(trends.flagChange > 0 ? "+" : "")\(trends.flagChange)",
                    percent: nil,
                    icon: "flag",
                    isNegativeGood: true,
                    rawValue: Double(trends.flagChange)
                )

                trendCard(
                    title: "Health",
                    value: String(format: "%.1f", trends.healthChange),
                    percent: nil,
                    icon: "heart",
                    rawValue: trends.healthChange
                )
            }
        }
    }

    private func trendCard(title: String, value: String, percent: Double?, icon: String, isNegativeGood: Bool = false, rawValue: Double? = nil) -> some View {
        let isPositive: Bool
        if let percent = percent {
            isPositive = isNegativeGood ? percent < 0 : percent >= 0
        } else if let rawValue = rawValue {
            isPositive = isNegativeGood ? rawValue <= 0 : rawValue >= 0
        } else {
            isPositive = true
        }

        return VStack(spacing: SteadyTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isPositive ? .steadySuccess : .steadyDestructive)

            Text(value)
                .font(.headline)
                .foregroundColor(.steadyText)

            if let percent = percent {
                HStack(spacing: 2) {
                    Image(systemName: percent >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2)
                    Text("\(String(format: "%.1f", abs(percent)))%")
                        .font(.caption2)
                }
                .foregroundColor(isPositive ? .steadySuccess : .steadyDestructive)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.steadyTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SteadyTheme.Spacing.md)
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.md)
    }

    private func snapshotsSection(_ snapshots: [HistorySnapshot]) -> some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            Text("Weekly Snapshots")
                .font(.headline)
                .foregroundColor(.steadyText)

            ForEach(snapshots.prefix(8)) { snapshot in
                snapshotRow(snapshot)
            }
        }
    }

    private func snapshotRow(_ snapshot: HistorySnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(snapshot.date))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.steadyText)

                Text("\(snapshot.siteCount) sites")
                    .font(.caption)
                    .foregroundColor(.steadyTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatCurrency(snapshot.totalValue))
                    .font(.subheadline)
                    .foregroundColor(.steadyText)

                HStack(spacing: 8) {
                    Label("\(snapshot.flagCount)", systemImage: "flag.fill")
                        .font(.caption2)
                        .foregroundColor(snapshot.flagCount > 0 ? .steadyWarning : .steadySuccess)

                    Text(String(format: "%.0f", snapshot.healthScore))
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.steadyPrimary)
                }
            }
        }
        .padding()
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.md)
    }

    private func moversSection(_ movers: [Mover]) -> some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            Text("Top Movers")
                .font(.headline)
                .foregroundColor(.steadyText)

            ForEach(movers.prefix(5)) { mover in
                moverRow(mover)
            }
        }
    }

    private func moverRow(_ mover: Mover) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(mover.itemName)
                    .font(.subheadline)
                    .foregroundColor(.steadyText)
                    .lineLimit(1)

                Text(mover.siteName)
                    .font(.caption)
                    .foregroundColor(.steadyTextSecondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: mover.direction == "up" ? "arrow.up.right" : "arrow.down.right")
                    .font(.caption)
                Text("\(String(format: "%.1f", abs(mover.changePercent)))%")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(mover.direction == "up" ? .steadySuccess : .steadyDestructive)
        }
        .padding()
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.md)
    }

    private var errorView: some View {
        VStack(spacing: SteadyTheme.Spacing.md) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.steadyTextSecondary)
            Text(errorMessage ?? "Failed to load history")
                .foregroundColor(.steadyTextSecondary)
            Button("Retry") {
                Task { await loadHistory() }
            }
            .steadyPrimaryButton()
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateStr) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        return dateStr
    }

    private func loadHistory() async {
        isLoading = true
        errorMessage = nil
        do {
            history = try await api.fetchHistory()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

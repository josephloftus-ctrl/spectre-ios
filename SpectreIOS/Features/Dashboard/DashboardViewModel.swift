import Foundation

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var summary: InventorySummary?
    @Published var isLoading = false
    @Published var errorMessage: String?

    var api: SpectreAPI?

    init(api: SpectreAPI? = nil) {
        self.api = api
    }

    func loadData() async {
        guard let api = api else {
            errorMessage = "API not configured"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            summary = try await api.fetchInventorySummary()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    var globalValueFormatted: String {
        guard let value = summary?.globalValue else { return "--" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }

    var activeSitesCount: String {
        guard let count = summary?.activeSites else { return "--" }
        return "\(count)"
    }

    var totalIssuesCount: String {
        guard let count = summary?.totalIssues else { return "--" }
        return "\(count)"
    }

    var sites: [SiteSummary] {
        summary?.sites ?? []
    }
}

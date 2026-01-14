import Foundation

@MainActor
class SpectreAPI: ObservableObject {
    private let client = APIClient()
    @Published var baseURL: URL?
    @Published var isConfigured: Bool = false

    init() {
        if let urlString = AppSettings.shared.backendURL,
           let url = URL(string: urlString) {
            self.baseURL = url
            self.isConfigured = true
        } else if let url = URL(string: AppSettings.defaultBackendURL) {
            self.baseURL = url
            self.isConfigured = true
        }
    }

    func updateBaseURL(_ urlString: String) {
        AppSettings.shared.backendURL = urlString
        self.baseURL = URL(string: urlString)
        self.isConfigured = baseURL != nil
    }

    func fetchInventorySummary() async throws -> InventorySummary {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/inventory/summary")
        return try await client.get(url: url)
    }

    func askHelpdesk(question: String) async throws -> HelpdeskResponse {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/helpdesk/ask")

        let formData = [
            "question": question,
            "include_sources": "true"
        ]

        return try await client.postForm(url: url, formData: formData)
    }
}

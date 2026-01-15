import Foundation

@MainActor
class SteadyAPI: ObservableObject {
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

    // MARK: - Inventory

    func fetchInventorySummary() async throws -> InventorySummary {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/inventory/summary")
        return try await client.get(url: url)
    }

    // MARK: - Helpdesk

    func askHelpdesk(question: String) async throws -> HelpdeskResponse {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/helpdesk/ask")

        let formData = [
            "question": question,
            "include_sources": "true"
        ]

        return try await client.postForm(url: url, formData: formData)
    }

    // MARK: - Search

    func search(query: String, collection: String? = nil) async throws -> SearchResponse {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/search")

        var formData = ["query": query]
        if let collection = collection {
            formData["collection"] = collection
        }

        return try await client.postForm(url: url, formData: formData)
    }

    // MARK: - Count Sessions

    func fetchCountSessions() async throws -> [CountSessionResponse] {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/counting/sessions")
        return try await client.get(url: url)
    }

    func createCountSession(siteId: String, name: String) async throws -> CountSessionResponse {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/counting/sessions")

        let formData = [
            "site_id": siteId,
            "name": name
        ]

        return try await client.postForm(url: url, formData: formData)
    }

    // MARK: - Notes (Memory)

    func fetchNotes() async throws -> [NoteResponse] {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/memory/notes")
        return try await client.get(url: url)
    }

    func saveNote(content: String, tags: [String] = []) async throws -> NoteResponse {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/memory/notes")

        var formData = ["content": content]
        if !tags.isEmpty {
            formData["tags"] = tags.joined(separator: ",")
        }

        return try await client.postForm(url: url, formData: formData)
    }
}

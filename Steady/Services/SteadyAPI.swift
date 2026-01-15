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

    func fetchSiteDetail(siteId: String) async throws -> SiteDetail {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/sites/\(siteId)")
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

    // MARK: - Chat

    func chat(message: String, history: [ChatHistoryItem]?) async throws -> ChatResponse {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/ai/chat")

        var formData = ["message": message]
        if let history = history, !history.isEmpty {
            let historyJSON = try? JSONEncoder().encode(history)
            if let data = historyJSON, let str = String(data: data, encoding: .utf8) {
                formData["history"] = str
            }
        }

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

    // MARK: - Standup

    func fetchStandup(forceRefresh: Bool = false) async throws -> StandupResponse {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        var url = base.appendingPathComponent("api/standup")
        if forceRefresh {
            url = url.appending(queryItems: [URLQueryItem(name: "refresh", value: "true")])
        }
        return try await client.get(url: url)
    }

    func rerollStandupSection(section: String) async throws -> StandupResponse {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        let url = base.appendingPathComponent("api/standup/reroll/\(section)")
        return try await client.postForm(url: url, formData: [:])
    }

    // MARK: - History

    func fetchHistory(siteId: String? = nil) async throws -> HistoryResponse {
        guard let base = baseURL else { throw NetworkError.invalidURL }
        var url = base.appendingPathComponent("api/history")
        if let siteId = siteId {
            url = url.appending(queryItems: [URLQueryItem(name: "site_id", value: siteId)])
        }
        return try await client.get(url: url)
    }
}

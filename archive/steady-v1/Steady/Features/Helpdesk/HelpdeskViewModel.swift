import Foundation

@MainActor
class HelpdeskViewModel: ObservableObject {
    @Published var question = ""
    @Published var response: HelpdeskResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingResponse = false

    var api: SteadyAPI?

    init(api: SteadyAPI? = nil) {
        self.api = api
    }

    func askQuestion() async {
        guard let api = api else {
            errorMessage = "API not configured"
            return
        }

        let trimmed = question.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            response = try await api.askHelpdesk(question: trimmed)
            showingResponse = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    func clearResponse() {
        response = nil
        showingResponse = false
        question = ""
    }
}

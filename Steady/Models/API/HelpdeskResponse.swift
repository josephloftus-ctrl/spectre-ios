import Foundation

struct HelpdeskResponse: Codable {
    let answer: String
    let confidence: String
    let sources: [String]?
    let sourceSnippets: [SourceSnippet]?

    enum CodingKeys: String, CodingKey {
        case answer
        case confidence
        case sources
        case sourceSnippets = "source_snippets"
    }
}

struct SourceSnippet: Codable, Identifiable {
    var id: String { file + text }

    let file: String
    let text: String
}

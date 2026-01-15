import Foundation

struct SearchResponse: Codable {
    let results: [SearchResult]
    let query: String
    let collection: String?
}

struct SearchResult: Codable, Identifiable {
    let id: String
    let content: String
    let source: String?
    let score: Double?
    let metadata: SearchMetadata?
}

struct SearchMetadata: Codable {
    let filename: String?
    let createdAt: String?
    let collection: String?
}

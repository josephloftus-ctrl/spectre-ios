import Foundation

struct NoteResponse: Codable, Identifiable {
    let id: String
    let content: String
    let tags: [String]
    let createdAt: String
    let updatedAt: String?
}

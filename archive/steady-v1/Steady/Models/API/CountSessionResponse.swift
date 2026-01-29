import Foundation

struct CountSessionResponse: Codable, Identifiable {
    let id: String
    let name: String
    let siteId: String
    let siteName: String?
    let status: String
    let itemCount: Int
    let createdAt: String
    let updatedAt: String?
}

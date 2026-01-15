import Foundation
import SwiftData

@Model
class Note {
    var id: UUID
    var content: String
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date
    var isSynced: Bool

    init(content: String, tags: [String] = []) {
        self.id = UUID()
        self.content = content
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isSynced = false
    }
}

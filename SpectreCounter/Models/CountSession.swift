import Foundation
import SwiftData

@Model
final class CountSession {
    var id: UUID
    var importedAt: Date
    var sourceFilename: String

    @Relationship(deleteRule: .cascade)
    var items: [InventoryItem]

    init(sourceFilename: String) {
        self.id = UUID()
        self.importedAt = Date()
        self.sourceFilename = sourceFilename
        self.items = []
    }

    var countedCount: Int {
        items.filter { $0.isCounted }.count
    }

    var totalCount: Int {
        items.count
    }
}

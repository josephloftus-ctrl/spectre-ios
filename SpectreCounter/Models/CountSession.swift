import Foundation
import SwiftData

@Model
final class CountSession {
    var id: UUID
    var importedAt: Date
    var sourceFilename: String
    var quantityColumn: String  // Column letter (e.g., "E") for quantity
    var templatePath: String    // Path to saved original template

    @Relationship(deleteRule: .cascade)
    var items: [InventoryItem]

    init(sourceFilename: String, quantityColumn: String, templatePath: String) {
        self.id = UUID()
        self.importedAt = Date()
        self.sourceFilename = sourceFilename
        self.quantityColumn = quantityColumn
        self.templatePath = templatePath
        self.items = []
    }

    var countedCount: Int {
        items.filter { $0.isCounted }.count
    }

    var totalCount: Int {
        items.count
    }
}

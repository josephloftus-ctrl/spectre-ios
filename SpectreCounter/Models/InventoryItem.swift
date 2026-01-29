import Foundation
import SwiftData

@Model
final class InventoryItem {
    var id: UUID
    var itemDescription: String
    var distNumber: String
    var custNumber: String?
    var uom: String
    var location: String
    var area: String
    var place: String

    // Counting state
    var count: Int
    var isCounted: Bool
    var countedAt: Date?

    // Original row index for export
    var rowIndex: Int

    init(
        itemDescription: String,
        distNumber: String,
        custNumber: String? = nil,
        uom: String,
        location: String,
        area: String,
        place: String,
        count: Int = 0,
        rowIndex: Int
    ) {
        self.id = UUID()
        self.itemDescription = itemDescription
        self.distNumber = distNumber
        self.custNumber = custNumber
        self.uom = uom
        self.location = location
        self.area = area
        self.place = place
        self.count = count
        self.isCounted = false
        self.countedAt = nil
        self.rowIndex = rowIndex
    }

    var locationKey: String {
        [location, area, place].filter { !$0.isEmpty }.joined(separator: " > ")
    }
}

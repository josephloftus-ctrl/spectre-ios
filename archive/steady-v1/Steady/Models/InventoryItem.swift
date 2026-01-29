import Foundation
import SwiftData

@Model
final class InventoryItem {
    @Attribute(.unique) var id: String
    var sku: String
    var name: String
    var quantity: Double
    var uom: String
    var location: String
    var lastUpdated: Date
    var isDirty: Bool // True if changed offline
    
    init(id: String = UUID().uuidString, sku: String, name: String, quantity: Double, uom: String, location: String) {
        self.id = id
        self.sku = sku
        self.name = name
        self.quantity = quantity
        self.uom = uom
        self.location = location
        self.lastUpdated = Date()
        self.isDirty = false
    }
}

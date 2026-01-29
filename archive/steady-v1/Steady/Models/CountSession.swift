import Foundation
import SwiftData

@Model
class CountSession {
    var id: UUID
    var name: String
    var siteId: String
    var siteName: String
    var status: CountSessionStatus
    var items: [CountItem]
    var createdAt: Date
    var updatedAt: Date

    init(name: String, siteId: String, siteName: String) {
        self.id = UUID()
        self.name = name
        self.siteId = siteId
        self.siteName = siteName
        self.status = .draft
        self.items = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

enum CountSessionStatus: String, Codable {
    case draft
    case inProgress
    case completed
}

struct CountItem: Codable, Identifiable {
    var id: UUID
    var sku: String
    var description: String
    var quantity: Double
    var uom: String
    var location: String?

    init(sku: String, description: String, quantity: Double = 0, uom: String = "EA", location: String? = nil) {
        self.id = UUID()
        self.sku = sku
        self.description = description
        self.quantity = quantity
        self.uom = uom
        self.location = location
    }
}

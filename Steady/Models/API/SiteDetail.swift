import Foundation

struct SiteDetail: Codable {
    let siteId: String
    let siteName: String
    let healthScore: Int
    let healthStatus: String
    let totalValue: Double
    let valueChange: Double
    let itemCount: Int
    let flagCount: Int
    let lastUpdated: String
    let flags: [ItemFlag]
    let rooms: [RoomSummary]
    let items: [InventoryItemSummary]
}

struct ItemFlag: Codable, Identifiable {
    var id: String { "\(itemName)-\(flagType)" }
    let itemName: String
    let sku: String?
    let flagType: String
    let reason: String
    let severity: String
    let location: String?
    let value: Double?
    let quantity: Double?
}

struct RoomSummary: Codable, Identifiable {
    var id: String { name }
    let name: String
    let itemCount: Int
    let totalValue: Double
}

struct InventoryItemSummary: Codable, Identifiable {
    var id: String { sku }
    let sku: String
    let description: String
    let quantity: Double
    let uom: String
    let value: Double
    let location: String?
    let hasFlag: Bool?
}

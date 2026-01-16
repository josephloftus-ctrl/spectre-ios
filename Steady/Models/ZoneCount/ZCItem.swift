import Foundation
import SwiftData

/// An inventory item that can be counted
@Model
class ZCItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var unit: String  // case, each, lb, gal, bag
    var category: String?  // Protein, Dairy, Produce, etc.
    var canonItemId: String?  // Links to canon item if created from template
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ZCZoneItem.item)
    var zoneItems: [ZCZoneItem]

    @Relationship(deleteRule: .nullify, inverse: \ZCCountEntry.item)
    var countEntries: [ZCCountEntry]

    init(name: String, unit: String, category: String? = nil, canonItemId: String? = nil) {
        self.id = UUID()
        self.name = name
        self.unit = unit
        self.category = category
        self.canonItemId = canonItemId
        self.createdAt = Date()
        self.zoneItems = []
        self.countEntries = []
    }

    /// Display string combining name and unit
    var displayName: String {
        "\(name) (\(unit))"
    }

    /// Check if this item came from a canon template
    var isFromCanon: Bool {
        canonItemId != nil
    }
}

/// Common units for inventory items
enum ItemUnit: String, CaseIterable, Identifiable {
    case each = "each"
    case caseUnit = "case"
    case lb = "lb"
    case oz = "oz"
    case gal = "gal"
    case qt = "qt"
    case bag = "bag"
    case container = "container"
    case bunch = "bunch"
    case box = "box"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .each: return "Each"
        case .caseUnit: return "Case"
        case .lb: return "Pound"
        case .oz: return "Ounce"
        case .gal: return "Gallon"
        case .qt: return "Quart"
        case .bag: return "Bag"
        case .container: return "Container"
        case .bunch: return "Bunch"
        case .box: return "Box"
        }
    }

    var abbreviation: String { rawValue }
}

/// Common item categories
enum ItemCategory: String, CaseIterable, Identifiable {
    case protein = "Protein"
    case dairy = "Dairy"
    case produce = "Produce"
    case prep = "Prep"
    case frozen = "Frozen"
    case canned = "Canned"
    case grain = "Grain"
    case baking = "Baking"
    case oil = "Oil"
    case paper = "Paper"
    case supply = "Supply"
    case chem = "Chem"
    case other = "Other"

    var id: String { rawValue }
}

import Foundation
import SwiftData

/// An individual count record within a session
@Model
class ZCCountEntry {
    @Attribute(.unique) var id: UUID
    var quantity: Double
    var timestamp: Date
    var note: String?  // "damaged", "expired", "new case opened"
    var skipped: Bool  // If the item was skipped during count

    var session: ZCCountSession?
    var zone: ZCZone?
    var item: ZCItem?

    init(
        session: ZCCountSession? = nil,
        zone: ZCZone? = nil,
        item: ZCItem? = nil,
        quantity: Double,
        note: String? = nil,
        skipped: Bool = false
    ) {
        self.id = UUID()
        self.session = session
        self.zone = zone
        self.item = item
        self.quantity = quantity
        self.timestamp = Date()
        self.note = note
        self.skipped = skipped
    }

    /// Get the zone item relationship for par level info
    var zoneItem: ZCZoneItem? {
        guard let zone = zone, let item = item else { return nil }
        return zone.zoneItems.first { $0.item?.id == item.id }
    }

    /// Variance from par level
    var variance: Double? {
        guard let par = zoneItem?.parLevel else { return nil }
        return quantity - par
    }

    /// Variance status for display
    var varianceStatus: VarianceStatus {
        zoneItem?.varianceStatus(quantity: quantity) ?? .unknown
    }

    /// Check if this entry was skipped
    var isSkipped: Bool {
        skipped || note?.lowercased().contains("skip") == true
    }

    /// Formatted quantity with unit
    var quantityDisplay: String {
        guard let unit = item?.unit else {
            return String(format: "%.1f", quantity)
        }

        // Show integer if whole number
        if quantity.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(quantity)) \(unit)"
        }
        return String(format: "%.1f %@", quantity, unit)
    }
}

/// Common notes for count entries
enum CountNote: String, CaseIterable, Identifiable {
    case damaged = "damaged"
    case expired = "expired"
    case newCase = "new case opened"
    case partial = "partial unit"
    case restock = "needs restock"
    case misplaced = "found elsewhere"

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var icon: String {
        switch self {
        case .damaged: return "exclamationmark.triangle"
        case .expired: return "clock.badge.xmark"
        case .newCase: return "shippingbox"
        case .partial: return "chart.pie"
        case .restock: return "arrow.clockwise"
        case .misplaced: return "questionmark.folder"
        }
    }
}

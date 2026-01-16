import Foundation
import SwiftData

/// Junction table linking items to zones with par levels and sort order
@Model
class ZCZoneItem {
    @Attribute(.unique) var id: UUID
    var parLevel: Double?  // Target quantity
    var sortOrder: Int  // Position within zone (shelf order)
    var createdAt: Date

    var zone: ZCZone?
    var item: ZCItem?

    init(zone: ZCZone? = nil, item: ZCItem? = nil, parLevel: Double? = nil, sortOrder: Int = 0) {
        self.id = UUID()
        self.zone = zone
        self.item = item
        self.parLevel = parLevel
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    /// Get the last counted quantity for this item in this zone
    func lastCountedQuantity(in session: ZCCountSession? = nil) -> Double? {
        guard let zone = zone, let item = item else { return nil }

        let entries: [ZCCountEntry]
        if let session = session {
            entries = session.entries.filter { $0.zone?.id == zone.id && $0.item?.id == item.id }
        } else {
            entries = zone.countEntries.filter { $0.item?.id == item.id }
        }

        return entries
            .sorted { $0.timestamp > $1.timestamp }
            .first?.quantity
    }

    /// Calculate variance from par level
    func variance(quantity: Double) -> Double? {
        guard let par = parLevel else { return nil }
        return quantity - par
    }

    /// Variance status for visual indicators
    func varianceStatus(quantity: Double) -> VarianceStatus {
        guard let par = parLevel, par > 0 else { return .unknown }

        let variancePct = (quantity - par) / par

        if variancePct < -0.25 {
            return .critical  // More than 25% under par
        } else if variancePct < 0 {
            return .warning  // Under par but within 25%
        } else {
            return .good  // At or above par
        }
    }
}

/// Visual status for variance from par
enum VarianceStatus {
    case critical  // Red - significantly under par
    case warning   // Yellow - slightly under par
    case good      // Green - at or above par
    case unknown   // No par level set

    var color: String {
        switch self {
        case .critical: return "red"
        case .warning: return "yellow"
        case .good: return "green"
        case .unknown: return "gray"
        }
    }

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .good: return "checkmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

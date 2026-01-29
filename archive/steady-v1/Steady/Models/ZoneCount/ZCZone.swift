import Foundation
import SwiftData
import simd

/// A storage area within a site (e.g., "WIC-01: Walk-in Cooler - Proteins")
/// Supports nesting: Room → Storage Areas → Shelves
@Model
class ZCZone {
    @Attribute(.unique) var id: UUID
    var name: String
    var code: String  // "WIC-01", "DRY-02" - appears on physical marker
    var zoneTypeRaw: String
    var sortOrder: Int  // Walking path sequence
    var createdAt: Date
    var updatedAt: Date

    // MARK: - AR Properties
    /// AR anchor position (x, y, z) relative to parent or world origin
    var arPositionX: Float = 0
    var arPositionY: Float = 0
    var arPositionZ: Float = 0
    /// Blob size in AR (radius in meters)
    var arBlobRadius: Float = 0.15
    /// Custom color hex (nil = use zone type default)
    var arColorHex: String?

    // MARK: - Nesting
    /// Parent zone (nil = root level zone)
    var parent: ZCZone?

    /// Child zones (sub-areas within this zone)
    @Relationship(deleteRule: .cascade, inverse: \ZCZone.parent)
    var children: [ZCZone]

    var site: ZCSite?

    @Relationship(deleteRule: .cascade, inverse: \ZCZoneItem.zone)
    var zoneItems: [ZCZoneItem]

    @Relationship(deleteRule: .nullify, inverse: \ZCCountEntry.zone)
    var countEntries: [ZCCountEntry]

    var zoneType: ZoneType {
        get { ZoneType(rawValue: zoneTypeRaw) ?? .other }
        set { zoneTypeRaw = newValue.rawValue }
    }

    /// AR position as SIMD vector
    var arPosition: SIMD3<Float> {
        get { SIMD3(arPositionX, arPositionY, arPositionZ) }
        set {
            arPositionX = newValue.x
            arPositionY = newValue.y
            arPositionZ = newValue.z
        }
    }

    init(
        name: String,
        code: String,
        zoneType: ZoneType,
        sortOrder: Int = 0,
        site: ZCSite? = nil,
        parent: ZCZone? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.code = code
        self.zoneTypeRaw = zoneType.rawValue
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
        self.site = site
        self.parent = parent
        self.children = []
        self.zoneItems = []
        self.countEntries = []
    }

    /// Display name combining code and name
    var displayName: String {
        "\(code): \(name)"
    }

    /// Number of items in this zone
    var itemCount: Int {
        zoneItems.count
    }

    /// Get items sorted by shelf position (sortOrder)
    var sortedItems: [ZCZoneItem] {
        zoneItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Get the last count entry for a specific item in this zone
    func lastCount(for item: ZCItem) -> ZCCountEntry? {
        countEntries
            .filter { $0.item?.id == item.id }
            .sorted { $0.timestamp > $1.timestamp }
            .first
    }

    // MARK: - Nesting Helpers

    /// Is this a leaf zone (no children, has items to count)
    var isLeaf: Bool {
        children.isEmpty
    }

    /// Is this a root zone (no parent)
    var isRoot: Bool {
        parent == nil
    }

    /// Depth in the hierarchy (0 = root)
    var depth: Int {
        var d = 0
        var current = parent
        while current != nil {
            d += 1
            current = current?.parent
        }
        return d
    }

    /// All descendant zones (recursive)
    var allDescendants: [ZCZone] {
        var result: [ZCZone] = []
        for child in children {
            result.append(child)
            result.append(contentsOf: child.allDescendants)
        }
        return result
    }

    /// Total items in this zone and all descendants
    var totalItemCount: Int {
        var count = zoneItems.count
        for child in children {
            count += child.totalItemCount
        }
        return count
    }

    /// Root zones for a site (no parent)
    static func rootZones(for site: ZCSite) -> [ZCZone] {
        site.zones.filter { $0.isRoot }
    }
}

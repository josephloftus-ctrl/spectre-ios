import Foundation
import SwiftData

/// Represents a physical location (kitchen, facility, account)
@Model
class ZCSite {
    @Attribute(.unique) var id: UUID
    var name: String
    var address: String?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ZCZone.site)
    var zones: [ZCZone]

    @Relationship(deleteRule: .cascade, inverse: \ZCCountSession.site)
    var countSessions: [ZCCountSession]

    init(name: String, address: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.address = address
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.zones = []
        self.countSessions = []
    }

    /// Formatted "last count" string
    var lastCountDisplay: String {
        guard let lastSession = countSessions
            .filter({ $0.status == .completed })
            .sorted(by: { $0.completedAt ?? .distantPast > $1.completedAt ?? .distantPast })
            .first,
              let completedAt = lastSession.completedAt else {
            return "Never"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: completedAt, relativeTo: Date())
    }

    /// Number of zones configured for this site
    var zoneCount: Int {
        zones.count
    }
}

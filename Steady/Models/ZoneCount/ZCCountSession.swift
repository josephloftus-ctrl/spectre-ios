import Foundation
import SwiftData

/// A single inventory count event at a site
@Model
class ZCCountSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var completedAt: Date?
    var countedBy: String?  // User identifier
    var statusRaw: String
    var notes: String?

    var site: ZCSite?

    @Relationship(deleteRule: .cascade, inverse: \ZCCountEntry.session)
    var entries: [ZCCountEntry]

    var status: ZCCountSessionStatus {
        get { ZCCountSessionStatus(rawValue: statusRaw) ?? .inProgress }
        set { statusRaw = newValue.rawValue }
    }

    init(site: ZCSite? = nil, countedBy: String? = nil) {
        self.id = UUID()
        self.startedAt = Date()
        self.completedAt = nil
        self.countedBy = countedBy
        self.statusRaw = ZCCountSessionStatus.inProgress.rawValue
        self.notes = nil
        self.site = site
        self.entries = []
    }

    /// Duration of the count session
    var duration: TimeInterval? {
        guard let end = completedAt else {
            return status == .inProgress ? Date().timeIntervalSince(startedAt) : nil
        }
        return end.timeIntervalSince(startedAt)
    }

    /// Formatted duration string
    var durationDisplay: String {
        guard let duration = duration else { return "--" }

        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60

        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m \(seconds)s"
        }
    }

    /// Number of zones that have been counted in this session
    var zonesCountedCount: Int {
        Set(entries.compactMap { $0.zone?.id }).count
    }

    /// Total zones at the site
    var totalZonesCount: Int {
        site?.zones.count ?? 0
    }

    /// Number of items counted
    var itemsCountedCount: Int {
        entries.count
    }

    /// Total items expected (sum of items across all zones)
    var totalItemsCount: Int {
        site?.zones.reduce(0) { $0 + $1.zoneItems.count } ?? 0
    }

    /// Items that were skipped (have a skip note)
    var skippedItemsCount: Int {
        entries.filter { $0.isSkipped }.count
    }

    /// Items under par
    var underParCount: Int {
        entries.filter { entry in
            guard let zoneItem = entry.zoneItem, let par = zoneItem.parLevel else { return false }
            return entry.quantity < par
        }.count
    }

    /// Items at or above par
    var atOrAboveParCount: Int {
        entries.filter { entry in
            guard let zoneItem = entry.zoneItem, let par = zoneItem.parLevel else { return false }
            return entry.quantity >= par
        }.count
    }

    /// Check if a specific zone has been fully counted
    func isZoneCounted(_ zone: ZCZone) -> Bool {
        let zoneEntries = entries.filter { $0.zone?.id == zone.id }
        return zoneEntries.count >= zone.zoneItems.count
    }

    /// Complete the session
    func complete() {
        status = .completed
        completedAt = Date()
    }

    /// Abandon the session
    func abandon() {
        status = .abandoned
        completedAt = Date()
    }
}

/// Status of a count session
enum ZCCountSessionStatus: String, Codable, CaseIterable {
    case inProgress = "in_progress"
    case completed = "completed"
    case abandoned = "abandoned"

    var displayName: String {
        switch self {
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .abandoned: return "Abandoned"
        }
    }

    var icon: String {
        switch self {
        case .inProgress: return "clock.arrow.circlepath"
        case .completed: return "checkmark.circle.fill"
        case .abandoned: return "xmark.circle.fill"
        }
    }
}

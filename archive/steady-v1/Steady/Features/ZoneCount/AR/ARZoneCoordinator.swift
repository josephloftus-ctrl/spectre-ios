import Foundation
import SwiftData
import RealityKit
import Observation

/// Coordinator for managing AR zone state and interactions
@Observable
class ARZoneCoordinator {
    var site: ZCSite?
    var modelContext: ModelContext?

    /// Map of zone IDs to zone objects for quick lookup
    var zoneMap: [UUID: ZCZone] = [:]

    /// Pending placement position when user taps to add zone
    var pendingPlacementPosition: SIMD3<Float>?

    /// Active count session
    var activeSession: ZCCountSession?

    /// Current count values (itemId -> quantity)
    var countValues: [UUID: Double] = [:]

    /// Notes for items
    var notes: [UUID: String] = [:]

    // MARK: - Zone Management

    func addZone(
        name: String,
        code: String,
        zoneType: ZoneType,
        parent: ZCZone?,
        position: SIMD3<Float>
    ) {
        guard let context = modelContext, let site = site else { return }

        let zone = ZCZone(
            name: name,
            code: code,
            zoneType: zoneType,
            site: site,
            parent: parent
        )

        zone.arPosition = position

        context.insert(zone)

        if let parent = parent {
            parent.children.append(zone)
        }

        site.zones.append(zone)

        try? context.save()
    }

    func updateZonePosition(_ zone: ZCZone, position: SIMD3<Float>) {
        zone.arPosition = position
        zone.updatedAt = Date()
        try? modelContext?.save()
    }

    func deleteZone(_ zone: ZCZone) {
        modelContext?.delete(zone)
        try? modelContext?.save()
    }

    // MARK: - Counting

    func setCount(_ quantity: Double, for item: ZCItem, in zone: ZCZone) {
        guard let itemId = item.id as UUID? else { return }
        countValues[itemId] = quantity
    }

    func getCount(for item: ZCItem) -> Double? {
        guard let itemId = item.id as UUID? else { return nil }
        return countValues[itemId]
    }

    func getExpectedCount(for zoneItem: ZCZoneItem) -> Double {
        zoneItem.parLevel ?? 0
    }

    func getVariance(for zoneItem: ZCZoneItem) -> Double? {
        guard let item = zoneItem.item,
              let actual = getCount(for: item),
              let expected = zoneItem.parLevel else { return nil }
        return actual - expected
    }

    func saveCountsForZone(_ zone: ZCZone) {
        guard let context = modelContext,
              let session = activeSession else { return }

        for zoneItem in zone.zoneItems {
            guard let item = zoneItem.item,
                  let itemId = item.id as UUID?,
                  let quantity = countValues[itemId] else { continue }

            let entry = ZCCountEntry(
                session: session,
                zone: zone,
                item: item,
                quantity: quantity,
                note: notes[itemId]
            )

            context.insert(entry)
            session.entries.append(entry)
        }

        try? context.save()
    }

    // MARK: - Session Management

    func startSession(for site: ZCSite, countedBy: String?) {
        guard let context = modelContext else { return }

        let session = ZCCountSession(site: site, countedBy: countedBy)
        context.insert(session)
        site.countSessions.append(session)
        activeSession = session

        try? context.save()
    }

    func completeSession() {
        activeSession?.complete()
        try? modelContext?.save()
        activeSession = nil
        countValues.removeAll()
        notes.removeAll()
    }
}

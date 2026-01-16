import Foundation
import SwiftData
import Observation

@Observable
class ZoneCountViewModel {
    var zone: ZCZone?
    var session: ZCCountSession?
    var countValues: [UUID: Double] = [:]  // itemId -> current count value
    var notes: [UUID: String] = [:]  // itemId -> note
    var skippedItems: Set<UUID> = []  // itemIds that were skipped

    var isLoading = false
    var errorMessage: String?
    var showingNoteSheet = false
    var selectedItemForNote: ZCZoneItem?

    private var modelContext: ModelContext?

    // MARK: - Computed Properties

    var sortedItems: [ZCZoneItem] {
        zone?.sortedItems ?? []
    }

    var totalItemCount: Int {
        sortedItems.count
    }

    var countedItemCount: Int {
        sortedItems.filter { item in
            guard let itemId = item.item?.id else { return false }
            return countValues[itemId] != nil || skippedItems.contains(itemId)
        }.count
    }

    var progress: Double {
        guard totalItemCount > 0 else { return 0 }
        return Double(countedItemCount) / Double(totalItemCount)
    }

    var isComplete: Bool {
        countedItemCount >= totalItemCount
    }

    var remainingCount: Int {
        totalItemCount - countedItemCount
    }

    // MARK: - Duration Tracking

    var zoneStartTime: Date?

    var currentDuration: TimeInterval {
        guard let start = zoneStartTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    var durationDisplay: String {
        let seconds = Int(currentDuration)
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    // MARK: - Initialization

    func configure(zone: ZCZone, session: ZCCountSession, modelContext: ModelContext) {
        self.zone = zone
        self.session = session
        self.modelContext = modelContext
        self.zoneStartTime = Date()

        // Pre-populate with last count values if available
        for zoneItem in zone.zoneItems {
            if let item = zoneItem.item,
               let lastEntry = zone.countEntries
                .filter({ $0.item?.id == item.id })
                .sorted(by: { $0.timestamp > $1.timestamp })
                .first {
                // Show last count as placeholder hint, don't auto-fill
            }
        }
    }

    // MARK: - Count Operations

    func count(for item: ZCZoneItem) -> Double? {
        guard let itemId = item.item?.id else { return nil }
        return countValues[itemId]
    }

    func setCount(_ value: Double, for item: ZCZoneItem) {
        guard let itemId = item.item?.id else { return }
        countValues[itemId] = max(0, value)
        skippedItems.remove(itemId)
    }

    func increment(for item: ZCZoneItem) {
        guard let itemId = item.item?.id else { return }
        let current = countValues[itemId] ?? 0
        countValues[itemId] = current + 1
        skippedItems.remove(itemId)
    }

    func decrement(for item: ZCZoneItem) {
        guard let itemId = item.item?.id else { return }
        let current = countValues[itemId] ?? 0
        countValues[itemId] = max(0, current - 1)
        skippedItems.remove(itemId)
    }

    func skip(item: ZCZoneItem) {
        guard let itemId = item.item?.id else { return }
        skippedItems.insert(itemId)
        countValues.removeValue(forKey: itemId)
    }

    func isSkipped(_ item: ZCZoneItem) -> Bool {
        guard let itemId = item.item?.id else { return false }
        return skippedItems.contains(itemId)
    }

    func isCounted(_ item: ZCZoneItem) -> Bool {
        guard let itemId = item.item?.id else { return false }
        return countValues[itemId] != nil
    }

    // MARK: - Notes

    func note(for item: ZCZoneItem) -> String? {
        guard let itemId = item.item?.id else { return nil }
        return notes[itemId]
    }

    func setNote(_ note: String?, for item: ZCZoneItem) {
        guard let itemId = item.item?.id else { return }
        if let note = note, !note.isEmpty {
            notes[itemId] = note
        } else {
            notes.removeValue(forKey: itemId)
        }
    }

    // MARK: - Last Count

    func lastCount(for item: ZCZoneItem) -> Double? {
        guard let zone = zone, let itemModel = item.item else { return nil }
        return zone.countEntries
            .filter { $0.item?.id == itemModel.id }
            .sorted { $0.timestamp > $1.timestamp }
            .first?.quantity
    }

    // MARK: - Variance

    func varianceStatus(for item: ZCZoneItem) -> VarianceStatus {
        guard let count = count(for: item) else { return .unknown }
        return item.varianceStatus(quantity: count)
    }

    // MARK: - Submit Zone

    func submitZone() {
        guard let zone = zone,
              let session = session,
              let context = modelContext else {
            errorMessage = "Missing zone or session"
            return
        }

        isLoading = true

        // Create entries for all counted items
        for zoneItem in zone.zoneItems {
            guard let item = zoneItem.item,
                  let itemId = item.id as UUID? else { continue }

            let isSkipped = skippedItems.contains(itemId)
            let quantity = countValues[itemId]

            // Skip items that weren't counted or skipped
            guard quantity != nil || isSkipped else { continue }

            let entry = ZCCountEntry(
                session: session,
                zone: zone,
                item: item,
                quantity: quantity ?? 0,
                note: notes[itemId],
                skipped: isSkipped
            )

            context.insert(entry)
            session.entries.append(entry)
            zone.countEntries.append(entry)
        }

        do {
            try context.save()
            isLoading = false
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

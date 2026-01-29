import Foundation

/// Manages ABC-XYZ classifications synced from Spectre
/// Classifications are cached in memory and refreshed periodically
@MainActor
class ClassificationManager: ObservableObject {
    static let shared = ClassificationManager()

    @Published private(set) var classifications: [String: [String: ItemClassification]] = [:]  // siteId -> (sku -> classification)
    @Published private(set) var lastSynced: [String: Date] = [:]  // siteId -> last sync time
    @Published var isLoading = false

    private let api = SteadyAPI()
    private let cacheExpirationSeconds: TimeInterval = 3600  // 1 hour

    private init() {}

    // MARK: - Public Methods

    /// Get ABC class for a SKU at a site
    func getABCClass(sku: String, siteId: String) -> String? {
        classifications[siteId]?[sku]?.abcClass
    }

    /// Get full classification for a SKU
    func getClassification(sku: String, siteId: String) -> ItemClassification? {
        classifications[siteId]?[sku]
    }

    /// Check if classifications need refresh for a site
    func needsRefresh(siteId: String) -> Bool {
        guard let lastSync = lastSynced[siteId] else { return true }
        return Date().timeIntervalSince(lastSync) > cacheExpirationSeconds
    }

    /// Sync classifications for a site (if stale or forced)
    func syncClassifications(siteId: String, force: Bool = false) async {
        guard force || needsRefresh(siteId: siteId) else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await api.fetchClassifications(siteId: siteId)

            // Build lookup dictionary
            var lookup: [String: ItemClassification] = [:]
            for item in response.items {
                lookup[item.sku] = item
            }

            classifications[siteId] = lookup
            lastSynced[siteId] = Date()

            print("Synced \(response.items.count) classifications for site \(siteId)")
        } catch {
            print("Failed to sync classifications for \(siteId): \(error)")
        }
    }

    /// Get sorted items by ABC class (A first, then B, then C, then unclassified)
    func sortByABC<T>(_ items: [T], siteId: String, skuKeyPath: KeyPath<T, String?>) -> [T] {
        items.sorted { a, b in
            let skuA = a[keyPath: skuKeyPath] ?? ""
            let skuB = b[keyPath: skuKeyPath] ?? ""

            let classA = getABCClass(sku: skuA, siteId: siteId) ?? "Z"
            let classB = getABCClass(sku: skuB, siteId: siteId) ?? "Z"

            return classA < classB
        }
    }

    /// Clear all cached classifications
    func clearCache() {
        classifications.removeAll()
        lastSynced.removeAll()
    }
}

// MARK: - ABC Class Helpers

extension String {
    /// Convert ABC class to sort priority (A=1, B=2, C=3, unknown=4)
    var abcSortPriority: Int {
        switch self.uppercased() {
        case "A": return 1
        case "B": return 2
        case "C": return 3
        default: return 4
        }
    }
}

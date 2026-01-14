import SwiftUI
import SwiftData

@main
struct SpectreApp: App {
    @StateObject private var api = SpectreAPI()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            InventoryItem.self,
            ScanSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(api)
        }
        .modelContainer(sharedModelContainer)
    }
}

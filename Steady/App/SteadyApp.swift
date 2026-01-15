import SwiftUI
import SwiftData

@main
struct SteadyApp: App {
    @StateObject private var api = SteadyAPI()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            InventoryItem.self,
            ScanSession.self,
            Note.self,
            CountSession.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [modelConfiguration])
    }()

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(api)
                .preferredColorScheme(.dark)
                .tint(.steadyPrimary)
        }
        .modelContainer(sharedModelContainer)
    }
}

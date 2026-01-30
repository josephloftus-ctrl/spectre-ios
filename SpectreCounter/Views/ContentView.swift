import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var sessions: [CountSession]
    @State private var activeSession: CountSession?

    var body: some View {
        Group {
            if let session = activeSession {
                CountingView(session: session, activeSession: $activeSession)
            } else {
                ImportView(activeSession: $activeSession)
            }
        }
        .onAppear {
            // Restore active session from SwiftData if available
            if activeSession == nil, let existingSession = sessions.first {
                activeSession = existingSession
            }
        }
    }
}

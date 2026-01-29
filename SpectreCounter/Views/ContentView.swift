import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var activeSession: CountSession?

    var body: some View {
        Group {
            if let session = activeSession {
                CountingView(session: session, activeSession: $activeSession)
            } else {
                ImportView(activeSession: $activeSession)
            }
        }
    }
}

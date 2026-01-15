import SwiftUI
import SwiftData

struct CountSessionsView: View {
    @EnvironmentObject var api: SteadyAPI
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CountSession.createdAt, order: .reverse) private var sessions: [CountSession]
    @State private var showingNewSession = false
    @State private var remoteSessions: [CountSessionResponse] = []
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                if sessions.isEmpty && remoteSessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle("Count Sessions")
            .toolbarBackground(SteadyTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewSession = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.steadyPrimary)
                    }
                }
            }
            .refreshable {
                await loadRemoteSessions()
            }
            .task {
                await loadRemoteSessions()
            }
            .sheet(isPresented: $showingNewSession) {
                NewCountSessionView()
            }
        }
    }

    private var sessionsList: some View {
        ScrollView {
            LazyVStack(spacing: SteadyTheme.Spacing.sm) {
                if !sessions.isEmpty {
                    Section {
                        ForEach(sessions) { session in
                            CountSessionCardView(
                                name: session.name,
                                siteName: session.siteName,
                                status: session.status.rawValue,
                                itemCount: session.items.count,
                                date: session.createdAt
                            )
                        }
                    } header: {
                        sectionHeader("Local Sessions")
                    }
                }

                if !remoteSessions.isEmpty {
                    Section {
                        ForEach(remoteSessions) { session in
                            CountSessionCardView(
                                name: session.name,
                                siteName: session.siteName ?? session.siteId,
                                status: session.status,
                                itemCount: session.itemCount,
                                date: ISO8601DateFormatter().date(from: session.createdAt) ?? Date()
                            )
                        }
                    } header: {
                        sectionHeader("Server Sessions")
                    }
                }
            }
            .padding()
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.steadyText)
            Spacer()
        }
        .padding(.top, SteadyTheme.Spacing.sm)
    }

    private var emptyStateView: some View {
        VStack(spacing: SteadyTheme.Spacing.md) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 48))
                .foregroundColor(.steadyTextSecondary)

            Text("No count sessions")
                .font(.headline)
                .foregroundColor(.steadyText)

            Text("Start a new inventory count session")
                .font(.subheadline)
                .foregroundColor(.steadyTextSecondary)

            Button {
                showingNewSession = true
            } label: {
                Label("New Session", systemImage: "plus")
            }
            .steadyPrimaryButton()
            .padding(.top, SteadyTheme.Spacing.md)
        }
    }

    private func loadRemoteSessions() async {
        isLoading = true
        do {
            remoteSessions = try await api.fetchCountSessions()
        } catch {
            // Silently fail, show local sessions only
        }
        isLoading = false
    }
}

struct CountSessionCardView: View {
    let name: String
    let siteName: String
    let status: String
    let itemCount: Int
    let date: Date

    var statusColor: Color {
        switch status.lowercased() {
        case "completed":
            return .steadySuccess
        case "inprogress", "in_progress":
            return .steadyWarning
        default:
            return .steadyTextSecondary
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(.steadyText)

                    Text(siteName)
                        .font(.subheadline)
                        .foregroundColor(.steadyTextSecondary)
                }

                Spacer()

                Text(status.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(SteadyTheme.Radius.sm)
            }

            HStack {
                Label("\(itemCount) items", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.steadyTextSecondary)

                Spacer()

                Text(date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.steadyTextTertiary)
            }
        }
        .padding()
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.lg)
                .stroke(SteadyTheme.borderSubtle, lineWidth: 1)
        )
    }
}

struct NewCountSessionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var siteName = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                VStack(spacing: SteadyTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
                        Text("Session Name")
                            .font(.caption)
                            .foregroundColor(.steadyTextSecondary)

                        TextField("e.g., Weekly Count", text: $name)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(SteadyTheme.cardBackground)
                            .cornerRadius(SteadyTheme.Radius.md)
                    }

                    VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
                        Text("Site Name")
                            .font(.caption)
                            .foregroundColor(.steadyTextSecondary)

                        TextField("e.g., Main Kitchen", text: $siteName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(SteadyTheme.cardBackground)
                            .cornerRadius(SteadyTheme.Radius.md)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Count Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSession()
                        dismiss()
                    }
                    .disabled(name.isEmpty || siteName.isEmpty)
                }
            }
        }
    }

    private func createSession() {
        let session = CountSession(
            name: name,
            siteId: siteName.lowercased().replacingOccurrences(of: " ", with: "-"),
            siteName: siteName
        )
        modelContext.insert(session)
    }
}

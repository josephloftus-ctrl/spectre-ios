import SwiftUI

struct StandupView: View {
    @EnvironmentObject var api: SteadyAPI
    @State private var standup: StandupResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var expandedSections: Set<String> = ["safety", "dei", "prompt"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView("Generating standup...")
                } else if let standup = standup {
                    standupContent(standup)
                } else {
                    errorView
                }
            }
            .navigationTitle("Daily Standup")
            .toolbarBackground(SteadyTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task { await loadStandup(forceRefresh: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.steadyPrimary)
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadStandup()
            }
        }
    }

    private func standupContent(_ standup: StandupResponse) -> some View {
        ScrollView {
            VStack(spacing: SteadyTheme.Spacing.md) {
                dateHeader(standup.date)

                standupSection(
                    id: "safety",
                    title: "Safety Moment",
                    icon: "shield.checkered",
                    color: .steadySuccess,
                    content: standup.safetyMoment,
                    sources: standup.safetySources
                )

                standupSection(
                    id: "dei",
                    title: "DEI Observance",
                    icon: "person.3.fill",
                    color: .steadyInfo,
                    content: standup.deiMoment,
                    sources: standup.deiSources
                )

                standupSection(
                    id: "prompt",
                    title: "Manager Prompt",
                    icon: "lightbulb.fill",
                    color: .steadyWarning,
                    content: standup.managerPrompt,
                    sources: nil
                )

                if !standup.criticalIssues.isEmpty {
                    criticalIssuesSection(standup.criticalIssues)
                }
            }
            .padding()
        }
        .refreshable {
            await loadStandup(forceRefresh: true)
        }
    }

    private func dateHeader(_ date: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good Morning")
                    .font(.headline)
                    .foregroundColor(.steadyTextSecondary)
                Text(formatDate(date))
                    .font(.title2.weight(.bold))
                    .foregroundColor(.steadyText)
            }
            Spacer()
            Image(systemName: "sun.max.fill")
                .font(.title)
                .foregroundColor(.steadyWarning)
        }
        .padding()
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.lg)
    }

    private func standupSection(id: String, title: String, icon: String, color: Color, content: String, sources: [String]?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    if expandedSections.contains(id) {
                        expandedSections.remove(id)
                    } else {
                        expandedSections.insert(id)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                        .frame(width: 32)

                    Text(title)
                        .font(.headline)
                        .foregroundColor(.steadyText)

                    Spacer()

                    Image(systemName: expandedSections.contains(id) ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.steadyTextSecondary)
                }
                .padding()
                .background(SteadyTheme.cardBackground)
            }
            .buttonStyle(.plain)

            if expandedSections.contains(id) {
                VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
                    Text(content)
                        .font(.body)
                        .foregroundColor(.steadyText)
                        .fixedSize(horizontal: false, vertical: true)

                    if let sources = sources, !sources.isEmpty {
                        Divider()
                            .background(SteadyTheme.border)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sources")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.steadyTextSecondary)

                            ForEach(sources, id: \.self) { source in
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                        .font(.caption2)
                                    Text(source)
                                        .font(.caption)
                                }
                                .foregroundColor(.steadyPrimary)
                            }
                        }
                    }

                    Button {
                        Task { await rerollSection(id) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                            Text("Regenerate")
                        }
                        .font(.caption)
                        .foregroundColor(.steadyPrimary)
                    }
                    .padding(.top, SteadyTheme.Spacing.xs)
                }
                .padding()
                .background(SteadyTheme.secondaryBackground)
            }
        }
        .cornerRadius(SteadyTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.lg)
                .stroke(SteadyTheme.borderSubtle, lineWidth: 1)
        )
    }

    private func criticalIssuesSection(_ issues: [CriticalIssue]) -> some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.steadyDestructive)
                Text("Critical Issues")
                    .font(.headline)
                    .foregroundColor(.steadyText)
            }
            .padding(.bottom, SteadyTheme.Spacing.xs)

            ForEach(issues) { issue in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(issue.siteName)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.steadyText)
                        Text(issue.description)
                            .font(.caption)
                            .foregroundColor(.steadyTextSecondary)
                    }
                    Spacer()
                    Text("\(issue.score)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.steadyDestructive)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.steadyDestructive.opacity(0.15))
                        .cornerRadius(SteadyTheme.Radius.sm)
                }
                .padding()
                .background(SteadyTheme.cardBackground)
                .cornerRadius(SteadyTheme.Radius.md)
            }
        }
        .padding()
        .background(SteadyTheme.destructive.opacity(0.05))
        .cornerRadius(SteadyTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.lg)
                .stroke(SteadyTheme.destructive.opacity(0.3), lineWidth: 1)
        )
    }

    private var errorView: some View {
        VStack(spacing: SteadyTheme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.steadyWarning)
            Text(errorMessage ?? "Failed to load standup")
                .foregroundColor(.steadyTextSecondary)
            Button("Retry") {
                Task { await loadStandup() }
            }
            .steadyPrimaryButton()
        }
    }

    private func formatDate(_ dateStr: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: dateStr) {
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date)
        }
        return dateStr
    }

    private func loadStandup(forceRefresh: Bool = false) async {
        isLoading = true
        errorMessage = nil
        do {
            standup = try await api.fetchStandup(forceRefresh: forceRefresh)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func rerollSection(_ section: String) async {
        // Reroll specific section
        do {
            standup = try await api.rerollStandupSection(section: section)
        } catch {
            // Handle error silently for now
        }
    }
}

// MARK: - Models

struct StandupResponse: Codable {
    let date: String
    let safetyMoment: String
    let safetySources: [String]?
    let deiMoment: String
    let deiSources: [String]?
    let managerPrompt: String
    let criticalIssues: [CriticalIssue]
}

struct CriticalIssue: Codable, Identifiable {
    var id: String { siteName }
    let siteName: String
    let description: String
    let score: Int
}

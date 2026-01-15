import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var api: SteadyAPI
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var helpdeskVM = HelpdeskViewModel()
    @State private var showingQuickActions = false

    var body: some View {
        TabView {
            dashboardTab
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            ChatView()
                .tabItem {
                    Label("Assistant", systemImage: "sparkles")
                }

            StandupView()
                .tabItem {
                    Label("Standup", systemImage: "sun.max.fill")
                }

            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }

    private var dashboardTab: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.steadyBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SteadyTheme.Spacing.md) {
                        kpiCardsSection
                        quickLinksSection
                        siteListSection
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
                .refreshable {
                    await dashboardVM.loadData()
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        QuickActionsButton(isExpanded: $showingQuickActions)
                            .padding(.trailing, SteadyTheme.Spacing.md)
                            .padding(.bottom, 100)
                    }
                }

                HelpdeskBarView(viewModel: helpdeskVM)
            }
            .navigationTitle("Steady")
            .toolbarBackground(SteadyTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: SiteSummary.self) { site in
                SiteDetailView(site: site)
            }
            .task {
                dashboardVM.api = api
                helpdeskVM.api = api
                await dashboardVM.loadData()
            }
            .alert("Error", isPresented: .constant(dashboardVM.errorMessage != nil)) {
                Button("OK") { dashboardVM.errorMessage = nil }
            } message: {
                Text(dashboardVM.errorMessage ?? "")
            }
        }
    }

    private var kpiCardsSection: some View {
        HStack(spacing: 12) {
            KPICardView(
                title: "Global Value",
                value: dashboardVM.globalValueFormatted,
                icon: "dollarsign.circle.fill",
                color: .green
            )

            KPICardView(
                title: "Active Sites",
                value: dashboardVM.activeSitesCount,
                icon: "building.2.fill",
                color: .blue
            )

            KPICardView(
                title: "Issues",
                value: dashboardVM.totalIssuesCount,
                icon: "exclamationmark.triangle.fill",
                color: .orange
            )
        }
    }

    private var quickLinksSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SteadyTheme.Spacing.sm) {
                NavigationLink(destination: CountSessionsView()) {
                    quickLinkCard(icon: "list.clipboard", title: "Count", color: .steadySuccess)
                }

                NavigationLink(destination: SearchView()) {
                    quickLinkCard(icon: "magnifyingglass", title: "Search", color: .steadyInfo)
                }

                NavigationLink(destination: HistoryView()) {
                    quickLinkCard(icon: "chart.line.uptrend.xyaxis", title: "Trends", color: .steadyPrimary)
                }
            }
        }
    }

    private func quickLinkCard(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: SteadyTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.steadyTextSecondary)
        }
        .frame(width: 80, height: 70)
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.md)
                .stroke(SteadyTheme.borderSubtle, lineWidth: 1)
        )
    }

    private var siteListSection: some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            HStack {
                Text("Sites")
                    .font(.headline)
                    .foregroundColor(.steadyText)

                Spacer()

                if !dashboardVM.sites.isEmpty {
                    Text("\(dashboardVM.sites.count) total")
                        .font(.caption)
                        .foregroundColor(.steadyTextSecondary)
                }
            }
            .padding(.horizontal, 4)

            if dashboardVM.isLoading && dashboardVM.sites.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if dashboardVM.sites.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(dashboardVM.sites) { site in
                        NavigationLink(value: site) {
                            SiteRowView(site: site)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: SteadyTheme.Spacing.sm) {
            Image(systemName: "building.2")
                .font(.largeTitle)
                .foregroundColor(.steadyTextSecondary)
            Text("No sites found")
                .foregroundColor(.steadyTextSecondary)
            Text("Check your backend connection in Settings")
                .font(.caption)
                .foregroundColor(.steadyTextTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}

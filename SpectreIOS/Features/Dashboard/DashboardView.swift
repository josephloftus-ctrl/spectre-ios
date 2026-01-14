import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var api: SpectreAPI
    @StateObject private var dashboardVM = DashboardViewModel()
    @StateObject private var helpdeskVM = HelpdeskViewModel()

    var body: some View {
        TabView {
            dashboardTab
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }

    private var dashboardTab: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color.spectreBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: SpectreTheme.Spacing.md) {
                        kpiCardsSection
                        siteListSection
                    }
                    .padding()
                    .padding(.bottom, 80)
                }
                .refreshable {
                    await dashboardVM.loadData()
                }

                HelpdeskBarView(viewModel: helpdeskVM)
            }
            .navigationTitle("Steady")
            .toolbarBackground(SpectreTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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

    private var siteListSection: some View {
        VStack(alignment: .leading, spacing: SpectreTheme.Spacing.sm) {
            Text("Sites")
                .font(.headline)
                .foregroundColor(.spectreText)
                .padding(.horizontal, 4)

            if dashboardVM.isLoading && dashboardVM.sites.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if dashboardVM.sites.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(dashboardVM.sites) { site in
                        SiteRowView(site: site)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: SpectreTheme.Spacing.sm) {
            Image(systemName: "building.2")
                .font(.largeTitle)
                .foregroundColor(.spectreTextSecondary)
            Text("No sites found")
                .foregroundColor(.spectreTextSecondary)
            Text("Check your backend connection in Settings")
                .font(.caption)
                .foregroundColor(.spectreTextTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}

import SwiftUI
import SwiftData

struct ZCSitesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ZCSite.name) private var sites: [ZCSite]

    @State private var showingAddSite = false
    @State private var selectedSiteForAR: ZCSite?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                if sites.isEmpty {
                    emptyState
                } else {
                    sitesList
                }
            }
            .navigationTitle("ZoneCount")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSite = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSite) {
                AddSiteSheet()
            }
            .sheet(item: $selectedSiteForAR) { site in
                StartARCountView(site: site)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: SteadyTheme.Spacing.lg) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.steadyTextTertiary)

            VStack(spacing: SteadyTheme.Spacing.sm) {
                Text("No Sites Yet")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.steadyText)

                Text("Add your first site to start zone-based inventory counting")
                    .font(.body)
                    .foregroundColor(.steadyTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showingAddSite = true
            } label: {
                Label("Add Site", systemImage: "plus")
            }
            .buttonStyle(SteadyPrimaryButtonStyle())
        }
        .padding(SteadyTheme.Spacing.xl)
    }

    private var sitesList: some View {
        ScrollView {
            LazyVStack(spacing: SteadyTheme.Spacing.sm) {
                ForEach(sites) { site in
                    siteRow(site)
                }
            }
            .padding(SteadyTheme.Spacing.md)
        }
    }

    private func siteRow(_ site: ZCSite) -> some View {
        HStack(spacing: SteadyTheme.Spacing.md) {
            // Site icon
            Image(systemName: "building.2.fill")
                .font(.title2)
                .foregroundColor(.steadyPrimary)
                .frame(width: 44, height: 44)
                .background(SteadyTheme.primary.opacity(0.15))
                .cornerRadius(SteadyTheme.Radius.md)

            // Site info
            VStack(alignment: .leading, spacing: 4) {
                Text(site.name)
                    .font(.headline)
                    .foregroundColor(.steadyText)

                HStack(spacing: SteadyTheme.Spacing.sm) {
                    Label("\(site.zoneCount) zones", systemImage: "square.grid.2x2")
                        .font(.caption)
                        .foregroundColor(.steadyTextSecondary)

                    Text("•")
                        .foregroundColor(.steadyTextTertiary)

                    Text("Last: \(site.lastCountDisplay)")
                        .font(.caption)
                        .foregroundColor(.steadyTextTertiary)
                }
            }

            Spacer()

            // AR Count button
            Button {
                selectedSiteForAR = site
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arkit")
                    Text("Count")
                }
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(SteadyTheme.primary)
                .clipShape(Capsule())
            }

            // Navigate to zone management
            NavigationLink {
                SiteZonesView(site: site)
            } label: {
                Image(systemName: "gearshape")
                    .font(.body)
                    .foregroundColor(.steadyTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(SteadyTheme.secondaryBackground)
                    .clipShape(Circle())
            }
        }
        .padding(SteadyTheme.Spacing.md)
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.lg)
                .stroke(SteadyTheme.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Add Site Sheet

struct AddSiteSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Site Name", text: $name)
                    TextField("Address (optional)", text: $address)
                }
            }
            .scrollContentBackground(.hidden)
            .background(SteadyTheme.background)
            .navigationTitle("Add Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addSite()
                    }
                    .font(.body.weight(.semibold))
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func addSite() {
        let site = ZCSite(
            name: name,
            address: address.isEmpty ? nil : address
        )
        modelContext.insert(site)
        dismiss()
    }
}

#Preview {
    ZCSitesListView()
        .preferredColorScheme(.dark)
}

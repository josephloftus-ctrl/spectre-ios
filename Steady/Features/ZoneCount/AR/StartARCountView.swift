import SwiftUI
import SwiftData

/// Entry point for starting an AR counting session
struct StartARCountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let site: ZCSite

    @State private var countedBy = ""
    @State private var showingARView = false
    @State private var session: ZCCountSession?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Site header
                VStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.steadyPrimary)

                    Text(site.name)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.steadyText)

                    Text("\(site.zones.count) zones configured")
                        .font(.subheadline)
                        .foregroundColor(.steadyTextSecondary)
                }
                .padding(.top, 40)

                // Zone preview
                if !site.zones.isEmpty {
                    zonePreview
                }

                Spacer()

                // Counter name (optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Counted By (optional)")
                        .font(.caption)
                        .foregroundColor(.steadyTextSecondary)

                    TextField("Your name", text: $countedBy)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(SteadyTheme.secondaryBackground)
                        .cornerRadius(SteadyTheme.Radius.md)
                }
                .padding(.horizontal)

                // Start AR button
                Button {
                    startSession()
                } label: {
                    HStack {
                        Image(systemName: "arkit")
                        Text("Start AR Count")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(SteadyTheme.primary)
                    .cornerRadius(SteadyTheme.Radius.lg)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(SteadyTheme.background)
            .navigationTitle("New Count")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingARView) {
                if let session = session {
                    ARZoneCountView(site: site, session: session)
                }
            }
        }
    }

    private var zonePreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Zones to Count")
                .font(.caption)
                .foregroundColor(.steadyTextSecondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ZCZone.rootZones(for: site).prefix(5)) { zone in
                        zoneCard(zone)
                    }

                    if site.zones.count > 5 {
                        VStack {
                            Text("+\(site.zones.count - 5)")
                                .font(.title3.weight(.bold))
                                .foregroundColor(.steadyTextSecondary)
                            Text("more")
                                .font(.caption)
                                .foregroundColor(.steadyTextTertiary)
                        }
                        .frame(width: 80, height: 80)
                        .background(SteadyTheme.secondaryBackground)
                        .cornerRadius(SteadyTheme.Radius.md)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func zoneCard(_ zone: ZCZone) -> some View {
        VStack(spacing: 8) {
            Image(systemName: zone.zoneType.icon)
                .font(.title2)
                .foregroundColor(zone.zoneType.iconColor)

            Text(zone.code)
                .font(.caption.weight(.medium))
                .foregroundColor(.steadyText)

            Text("\(zone.totalItemCount)")
                .font(.caption2)
                .foregroundColor(.steadyTextTertiary)
        }
        .frame(width: 80, height: 80)
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.md)
                .stroke(SteadyTheme.borderSubtle, lineWidth: 1)
        )
    }

    private func startSession() {
        let newSession = ZCCountSession(
            site: site,
            countedBy: countedBy.isEmpty ? nil : countedBy
        )
        modelContext.insert(newSession)
        site.countSessions.append(newSession)

        session = newSession
        showingARView = true
    }
}

#Preview {
    StartARCountView(site: ZCSite(name: "Test Site"))
        .preferredColorScheme(.dark)
}

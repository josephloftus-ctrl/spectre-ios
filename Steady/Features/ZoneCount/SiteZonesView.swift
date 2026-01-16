import SwiftUI
import SwiftData

struct SiteZonesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let site: ZCSite

    @State private var currentSession: ZCCountSession?
    @State private var selectedZone: ZCZone?
    @State private var showingZoneCount = false
    @State private var completedZones: Set<UUID> = []

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.steadyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Scan zone button
                scanButton

                // Zone list
                zoneList
            }

            // Session summary bar (when session active)
            if currentSession != nil {
                sessionBar
            }
        }
        .navigationTitle(site.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(SteadyTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            if currentSession != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") {
                        finishSession()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.steadySuccess)
                }
            }
        }
        .navigationDestination(isPresented: $showingZoneCount) {
            if let zone = selectedZone, let session = currentSession {
                ZoneCountView(zone: zone, session: session)
            }
        }
        .onAppear {
            // Start a new count session
            startSession()
        }
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        Button {
            // TODO: Implement QR/marker scanning
        } label: {
            HStack(spacing: SteadyTheme.Spacing.md) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.title)
                Text("Scan Zone to Start")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SteadyTheme.Spacing.lg)
            .background(SteadyTheme.primary)
            .cornerRadius(SteadyTheme.Radius.lg)
        }
        .padding(SteadyTheme.Spacing.md)
    }

    // MARK: - Zone List

    private var zoneList: some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            Text("Or select zone manually:")
                .font(.subheadline)
                .foregroundColor(.steadyTextSecondary)
                .padding(.horizontal, SteadyTheme.Spacing.md)

            ScrollView {
                LazyVStack(spacing: SteadyTheme.Spacing.sm) {
                    ForEach(site.zones.sorted { $0.sortOrder < $1.sortOrder }) { zone in
                        zoneRow(zone)
                    }
                }
                .padding(.horizontal, SteadyTheme.Spacing.md)
                .padding(.bottom, currentSession != nil ? 100 : 20)
            }
        }
    }

    private func zoneRow(_ zone: ZCZone) -> some View {
        let isCompleted = completedZones.contains(zone.id)

        return Button {
            selectZone(zone)
        } label: {
            HStack(spacing: SteadyTheme.Spacing.md) {
                // Status indicator
                ZStack {
                    Circle()
                        .stroke(
                            isCompleted ? SteadyTheme.success : SteadyTheme.border,
                            lineWidth: 2
                        )
                        .frame(width: 24, height: 24)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.steadySuccess)
                    }
                }

                // Zone icon
                Image(systemName: zone.zoneType.icon)
                    .font(.title3)
                    .foregroundColor(zone.zoneType.iconColor)
                    .frame(width: 32)

                // Zone info
                VStack(alignment: .leading, spacing: 2) {
                    Text(zone.code)
                        .font(.headline)
                        .foregroundColor(.steadyText)

                    Text(zone.name)
                        .font(.subheadline)
                        .foregroundColor(.steadyTextSecondary)
                }

                Spacer()

                // Item count
                Text("\(zone.itemCount) items")
                    .font(.caption)
                    .foregroundColor(.steadyTextTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(SteadyTheme.secondaryBackground)
                    .cornerRadius(SteadyTheme.Radius.sm)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.steadyTextTertiary)
            }
            .padding(SteadyTheme.Spacing.md)
            .background(SteadyTheme.cardBackground)
            .cornerRadius(SteadyTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: SteadyTheme.Radius.md)
                    .stroke(
                        isCompleted ? SteadyTheme.success.opacity(0.3) : SteadyTheme.borderSubtle,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Session Bar

    private var sessionBar: some View {
        VStack(spacing: 0) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(SteadyTheme.secondaryBackground)

                    Rectangle()
                        .fill(sessionProgress >= 1 ? SteadyTheme.success : SteadyTheme.primary)
                        .frame(width: geo.size.width * sessionProgress)
                        .animation(.spring(response: 0.3), value: sessionProgress)
                }
            }
            .frame(height: 4)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Count Session")
                        .font(.caption)
                        .foregroundColor(.steadyTextTertiary)

                    Text("\(completedZones.count)/\(site.zones.count) zones")
                        .font(.headline)
                        .foregroundColor(.steadyText)
                }

                Spacer()

                if let session = currentSession {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.steadyTextTertiary)

                        Text(session.durationDisplay)
                            .font(.headline.monospacedDigit())
                            .foregroundColor(.steadyText)
                    }
                }
            }
            .padding(SteadyTheme.Spacing.md)
        }
        .background(SteadyTheme.cardBackground)
    }

    private var sessionProgress: Double {
        guard !site.zones.isEmpty else { return 0 }
        return Double(completedZones.count) / Double(site.zones.count)
    }

    // MARK: - Actions

    private func startSession() {
        let session = ZCCountSession(site: site, countedBy: nil)
        modelContext.insert(session)
        site.countSessions.append(session)
        currentSession = session
    }

    private func selectZone(_ zone: ZCZone) {
        selectedZone = zone
        showingZoneCount = true
    }

    private func finishSession() {
        guard let session = currentSession else { return }
        session.complete()

        do {
            try modelContext.save()
        } catch {
            print("Error saving session: \(error)")
        }

        dismiss()
    }
}

// MARK: - Extension for zone completion tracking

extension SiteZonesView {
    func markZoneCompleted(_ zone: ZCZone) {
        completedZones.insert(zone.id)
    }
}

#Preview {
    NavigationStack {
        Text("SiteZonesView Preview")
            .foregroundColor(.steadyText)
    }
    .preferredColorScheme(.dark)
}

import SwiftUI
import RealityKit
import ARKit
import SwiftData

/// Main AR view for zone-based inventory counting
struct ARZoneCountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let site: ZCSite
    let session: ZCCountSession

    @State private var arCoordinator = ARZoneCoordinator()
    @State private var currentZone: ZCZone?  // nil = showing root zones
    @State private var navigationStack: [ZCZone] = []
    @State private var showingItemCount = false
    @State private var selectedLeafZone: ZCZone?
    @State private var isPlacementMode = false
    @State private var showingAddZone = false

    var body: some View {
        ZStack {
            // AR Camera View
            ARViewContainer(
                coordinator: arCoordinator,
                zones: visibleZones,
                onZoneTapped: handleZoneTap,
                onPlacementTap: handlePlacementTap,
                isPlacementMode: isPlacementMode
            )
            .ignoresSafeArea()

            // Overlay UI
            VStack {
                // Top bar
                topBar

                Spacer()

                // Bottom controls
                bottomControls
            }

            // Item count sheet (slides up when viewing leaf zone)
            if showingItemCount, let zone = selectedLeafZone {
                itemCountOverlay(zone: zone)
            }
        }
        .onAppear {
            arCoordinator.site = site
            arCoordinator.modelContext = modelContext
        }
        .sheet(isPresented: $showingAddZone) {
            AddARZoneSheet(
                site: site,
                parent: currentZone,
                arCoordinator: arCoordinator
            )
        }
    }

    // MARK: - Visible Zones

    private var visibleZones: [ZCZone] {
        if let current = currentZone {
            // Show children of current zone
            return current.children.sorted { $0.sortOrder < $1.sortOrder }
        } else {
            // Show root zones
            return ZCZone.rootZones(for: site).sorted { $0.sortOrder < $1.sortOrder }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Back button
            if currentZone != nil {
                Button {
                    navigateBack()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(currentZone?.parent?.name ?? site.name)
                    }
                    .font(.body.weight(.medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                }
            } else {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }

            Spacer()

            // Current location indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text(currentZone?.name ?? site.name)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(breadcrumbText)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }

    private var breadcrumbText: String {
        if navigationStack.isEmpty {
            return "\(visibleZones.count) zones"
        }
        return navigationStack.map { $0.code }.joined(separator: " → ")
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack(spacing: 16) {
            // Placement mode toggle
            Button {
                isPlacementMode.toggle()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: isPlacementMode ? "plus.circle.fill" : "plus.circle")
                        .font(.title2)
                    Text("Place")
                        .font(.caption2)
                }
                .foregroundColor(isPlacementMode ? .green : .white)
                .frame(width: 60, height: 60)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            // Zone count indicator
            VStack(spacing: 4) {
                Text("\(visibleZones.count)")
                    .font(.title.weight(.bold))
                Text("zones")
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Items indicator (if in a zone with items)
            if let zone = currentZone, zone.totalItemCount > 0 {
                VStack(spacing: 4) {
                    Text("\(zone.totalItemCount)")
                        .font(.title.weight(.bold))
                    Text("items")
                        .font(.caption2)
                }
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .padding(.bottom, 20)
    }

    // MARK: - Item Count Overlay

    private func itemCountOverlay(zone: ZCZone) -> some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                // Handle bar
                Capsule()
                    .fill(.white.opacity(0.3))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Zone header
                HStack {
                    VStack(alignment: .leading) {
                        Text(zone.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("\(zone.zoneItems.count) items to count")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button {
                        showingItemCount = false
                        selectedLeafZone = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 12)

                // Item list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(zone.sortedItems, id: \.id) { zoneItem in
                            ARItemCountRow(
                                zoneItem: zoneItem,
                                session: session
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 8)
        }
        .transition(.move(edge: .bottom))
    }

    // MARK: - Navigation

    private func handleZoneTap(_ zone: ZCZone) {
        if zone.isLeaf {
            // Show items to count
            selectedLeafZone = zone
            withAnimation(.spring(response: 0.3)) {
                showingItemCount = true
            }
        } else {
            // Drill into zone
            withAnimation(.spring(response: 0.4)) {
                navigationStack.append(zone)
                currentZone = zone
            }
        }
    }

    private func navigateBack() {
        withAnimation(.spring(response: 0.4)) {
            if navigationStack.count > 1 {
                navigationStack.removeLast()
                currentZone = navigationStack.last
            } else {
                navigationStack.removeAll()
                currentZone = nil
            }
        }
    }

    private func handlePlacementTap(position: SIMD3<Float>) {
        // Create new zone at tapped position
        showingAddZone = true
        arCoordinator.pendingPlacementPosition = position
    }
}

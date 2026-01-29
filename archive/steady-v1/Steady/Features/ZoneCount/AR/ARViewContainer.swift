import SwiftUI
import RealityKit
import ARKit
import Combine

/// UIViewRepresentable wrapper for RealityKit ARView
struct ARViewContainer: UIViewRepresentable {
    let coordinator: ARZoneCoordinator
    let zones: [ZCZone]
    let onZoneTapped: (ZCZone) -> Void
    let onPlacementTap: (SIMD3<Float>) -> Void
    let isPlacementMode: Bool

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // Configure AR session
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        arView.session.run(config)

        // Set up tap gesture
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        // Store reference
        context.coordinator.arView = arView
        context.coordinator.onZoneTapped = onZoneTapped
        context.coordinator.onPlacementTap = onPlacementTap

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.isPlacementMode = isPlacementMode
        context.coordinator.onZoneTapped = onZoneTapped
        context.coordinator.onPlacementTap = onPlacementTap
        context.coordinator.updateZoneBlobs(zones: zones)
    }

    func makeCoordinator() -> ARViewCoordinator {
        ARViewCoordinator(arCoordinator: coordinator)
    }
}

/// Coordinator for handling AR view interactions
class ARViewCoordinator: NSObject {
    weak var arView: ARView?
    let arCoordinator: ARZoneCoordinator
    var onZoneTapped: ((ZCZone) -> Void)?
    var onPlacementTap: ((SIMD3<Float>) -> Void)?
    var isPlacementMode = false

    private var zoneEntities: [UUID: ZoneBlobEntity] = [:]
    private var anchorEntity: AnchorEntity?

    init(arCoordinator: ARZoneCoordinator) {
        self.arCoordinator = arCoordinator
        super.init()
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let arView = arView else { return }

        let location = gesture.location(in: arView)

        if isPlacementMode {
            // Place new zone at tapped location
            if let result = arView.raycast(
                from: location,
                allowing: .estimatedPlane,
                alignment: .any
            ).first {
                let position = SIMD3<Float>(
                    result.worldTransform.columns.3.x,
                    result.worldTransform.columns.3.y,
                    result.worldTransform.columns.3.z
                )
                onPlacementTap?(position)
            }
        } else {
            // Check if tapped on a zone blob
            if let entity = arView.entity(at: location) {
                // Find the zone associated with this entity
                for (zoneId, blobEntity) in zoneEntities {
                    if isEntity(entity, descendantOf: blobEntity) || entity == blobEntity {
                        if let zone = arCoordinator.zoneMap[zoneId] {
                            // Animate blob
                            animateBlobTap(blobEntity)
                            onZoneTapped?(zone)
                        }
                        return
                    }
                }
            }
        }
    }

    func updateZoneBlobs(zones: [ZCZone]) {
        guard let arView = arView else { return }

        // Create anchor if needed
        if anchorEntity == nil {
            anchorEntity = AnchorEntity(world: .zero)
            arView.scene.addAnchor(anchorEntity!)
        }

        guard let anchor = anchorEntity else { return }

        // Track which zones we've processed
        var processedIds = Set<UUID>()

        for zone in zones {
            processedIds.insert(zone.id)
            arCoordinator.zoneMap[zone.id] = zone

            if let existingBlob = zoneEntities[zone.id] {
                // Update existing blob position
                existingBlob.position = zone.arPosition
            } else {
                // Create new blob
                let blob = ZoneBlobEntity(zone: zone)
                anchor.addChild(blob)
                zoneEntities[zone.id] = blob

                // Animate appearance
                blob.scale = .zero
                blob.transform.scale = .init(repeating: 0.01)

                var transform = blob.transform
                transform.scale = .init(repeating: 1.0)

                blob.move(
                    to: transform,
                    relativeTo: blob.parent,
                    duration: 0.4,
                    timingFunction: .easeOut
                )
            }
        }

        // Remove blobs for zones no longer visible
        for (zoneId, blob) in zoneEntities where !processedIds.contains(zoneId) {
            // Animate removal
            var transform = blob.transform
            transform.scale = .init(repeating: 0.01)

            blob.move(
                to: transform,
                relativeTo: blob.parent,
                duration: 0.3,
                timingFunction: .easeIn
            )

            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak blob] in
                blob?.removeFromParent()
            }

            zoneEntities.removeValue(forKey: zoneId)
            arCoordinator.zoneMap.removeValue(forKey: zoneId)
        }
    }

    private func animateBlobTap(_ blob: ZoneBlobEntity) {
        // Pulse animation on tap
        var scaleUp = blob.transform
        scaleUp.scale = .init(repeating: 1.2)

        var scaleNormal = blob.transform
        scaleNormal.scale = .init(repeating: 1.0)

        blob.move(
            to: scaleUp,
            relativeTo: blob.parent,
            duration: 0.1,
            timingFunction: .easeOut
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak blob] in
            blob?.move(
                to: scaleNormal,
                relativeTo: blob?.parent,
                duration: 0.2,
                timingFunction: .easeInOut
            )
        }
    }

    private func isEntity(_ entity: Entity, descendantOf ancestor: Entity) -> Bool {
        var current = entity.parent
        while let parent = current {
            if parent == ancestor {
                return true
            }
            current = parent.parent
        }
        return false
    }
}

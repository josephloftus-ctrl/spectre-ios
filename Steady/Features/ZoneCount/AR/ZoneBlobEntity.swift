import RealityKit
import UIKit
import SwiftUI

/// 3D blob entity representing a zone in AR space
class ZoneBlobEntity: Entity, HasModel, HasCollision {
    var zoneId: UUID
    var zoneName: String
    var zoneTypeRaw: String
    var blobRadius: Float
    var colorHex: String?
    var isLeafZone: Bool
    var itemCount: Int
    var childCount: Int

    required init() {
        self.zoneId = UUID()
        self.zoneName = ""
        self.zoneTypeRaw = ZoneType.other.rawValue
        self.blobRadius = 0.15
        self.colorHex = nil
        self.isLeafZone = true
        self.itemCount = 0
        self.childCount = 0
        super.init()
    }

    convenience init(zone: ZCZone) {
        self.init()
        self.zoneId = zone.id
        self.zoneName = zone.name
        self.zoneTypeRaw = zone.zoneTypeRaw
        self.blobRadius = zone.arBlobRadius
        self.colorHex = zone.arColorHex
        self.isLeafZone = zone.isLeaf
        self.itemCount = zone.zoneItems.count
        self.childCount = zone.children.count

        setupBlob()
        setupLabel()
        self.position = zone.arPosition
    }

    private var zoneType: ZoneType {
        ZoneType(rawValue: zoneTypeRaw) ?? .other
    }

    private func setupBlob() {
        // Create sphere mesh
        let radius = blobRadius
        let mesh = MeshResource.generateSphere(radius: radius)

        // Create material with zone color
        var material = SimpleMaterial()
        material.color = .init(tint: blobColor.withAlphaComponent(0.8))
        material.roughness = 0.3
        material.metallic = 0.1

        // Apply mesh and material
        self.model = ModelComponent(mesh: mesh, materials: [material])

        // Add collision for tap detection
        self.collision = CollisionComponent(shapes: [.generateSphere(radius: radius)])

        // Add pulsing animation
        addPulseAnimation()
    }

    private func setupLabel() {
        // Create text label above blob
        let labelEntity = createLabelEntity()
        labelEntity.position = SIMD3<Float>(0, blobRadius + 0.03, 0)
        addChild(labelEntity)

        // Create count badge if zone has items
        if isLeafZone && itemCount > 0 {
            let badgeEntity = createBadgeEntity(count: itemCount)
            badgeEntity.position = SIMD3<Float>(blobRadius * 0.7, blobRadius * 0.7, 0)
            addChild(badgeEntity)
        } else if childCount > 0 {
            // Show child count for parent zones
            let badgeEntity = createBadgeEntity(count: childCount, isChildCount: true)
            badgeEntity.position = SIMD3<Float>(blobRadius * 0.7, blobRadius * 0.7, 0)
            addChild(badgeEntity)
        }
    }

    private func createLabelEntity() -> Entity {
        let labelEntity = Entity()

        // Zone name text
        let textMesh = MeshResource.generateText(
            zoneName,
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.02, weight: .semibold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byTruncatingTail
        )

        var material = SimpleMaterial()
        material.color = .init(tint: .white)

        let textEntity = ModelEntity(mesh: textMesh, materials: [material])
        textEntity.position.x = -textMesh.bounds.extents.x / 2  // Center text

        labelEntity.addChild(textEntity)

        // Make label always face camera (billboard)
        // This is handled by updating in the render loop

        return labelEntity
    }

    private func createBadgeEntity(count: Int, isChildCount: Bool = false) -> Entity {
        let badgeEntity = Entity()

        // Badge background
        let badgeSize: Float = 0.025
        let badgeMesh = MeshResource.generateSphere(radius: badgeSize)

        var badgeMaterial = SimpleMaterial()
        badgeMaterial.color = .init(tint: isChildCount ? .systemBlue : .systemOrange)

        let badgeBackground = ModelEntity(mesh: badgeMesh, materials: [badgeMaterial])
        badgeEntity.addChild(badgeBackground)

        // Count text
        let countText = MeshResource.generateText(
            "\(count)",
            extrusionDepth: 0.001,
            font: .systemFont(ofSize: 0.015, weight: .bold),
            containerFrame: .zero,
            alignment: .center,
            lineBreakMode: .byClipping
        )

        var textMaterial = SimpleMaterial()
        textMaterial.color = .init(tint: .white)

        let countEntity = ModelEntity(mesh: countText, materials: [textMaterial])
        countEntity.position = SIMD3<Float>(
            -countText.bounds.extents.x / 2,
            -countText.bounds.extents.y / 2,
            badgeSize + 0.001
        )

        badgeEntity.addChild(countEntity)

        return badgeEntity
    }

    private var blobColor: UIColor {
        if let hex = colorHex {
            return UIColor(hex: hex) ?? zoneType.uiColor
        }
        return zoneType.uiColor
    }

    private func addPulseAnimation() {
        // Subtle breathing animation
        guard self.model != nil else { return }

        // Use a timer-based animation since RealityKit animations are limited
        // The actual implementation would use a custom system or component
    }
}

// MARK: - ZoneType UIColor

extension ZoneType {
    var uiColor: UIColor {
        switch self {
        case .walkInCooler: return .systemBlue
        case .walkInFreezer: return .systemCyan
        case .dryStorage: return .systemBrown
        case .reachInCooler: return .systemTeal
        case .reachInFreezer: return .systemIndigo
        case .lineStation: return .systemOrange
        case .other: return .systemGray
        }
    }
}

// MARK: - UIColor Hex Init

extension UIColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

import Foundation
import SwiftUI

/// Type of storage zone - determines canon items and visual cues
enum ZoneType: String, Codable, CaseIterable, Identifiable {
    case walkInCooler = "walk_in_cooler"
    case walkInFreezer = "walk_in_freezer"
    case dryStorage = "dry_storage"
    case reachInCooler = "reach_in_cooler"
    case reachInFreezer = "reach_in_freezer"
    case lineStation = "line_station"
    case other = "other"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .walkInCooler: return "Walk-in Cooler"
        case .walkInFreezer: return "Walk-in Freezer"
        case .dryStorage: return "Dry Storage"
        case .reachInCooler: return "Reach-in Cooler"
        case .reachInFreezer: return "Reach-in Freezer"
        case .lineStation: return "Line Station"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .walkInCooler: return "thermometer.snowflake"
        case .walkInFreezer: return "snowflake"
        case .dryStorage: return "archivebox"
        case .reachInCooler: return "refrigerator"
        case .reachInFreezer: return "refrigerator.fill"
        case .lineStation: return "flame"
        case .other: return "square.grid.2x2"
        }
    }

    var iconColor: Color {
        switch self {
        case .walkInCooler: return .blue
        case .walkInFreezer: return .cyan
        case .dryStorage: return .brown
        case .reachInCooler: return .teal
        case .reachInFreezer: return .indigo
        case .lineStation: return .orange
        case .other: return .gray
        }
    }

    /// Default zone code prefix
    var codePrefix: String {
        switch self {
        case .walkInCooler: return "WIC"
        case .walkInFreezer: return "WIF"
        case .dryStorage: return "DRY"
        case .reachInCooler: return "RIC"
        case .reachInFreezer: return "RIF"
        case .lineStation: return "LINE"
        case .other: return "ZONE"
        }
    }

    /// Visual cues for image recognition (future feature)
    var visualCues: [String] {
        switch self {
        case .walkInCooler:
            return ["Metal shelving", "Cold vapor", "Raw proteins visible", "Bright fluorescent lighting", "Condensation on surfaces"]
        case .walkInFreezer:
            return ["Frost buildup", "Frozen products", "Ice crystals", "Vapor when door opens"]
        case .dryStorage:
            return ["Metal or wire shelving", "Canned goods visible", "Bags of flour/rice", "Paper products", "No refrigeration"]
        case .reachInCooler:
            return ["Glass or solid door units", "Smaller scale", "Near cook line"]
        case .reachInFreezer:
            return ["Smaller freezer unit", "Near cook line", "Frost on door seal"]
        case .lineStation:
            return ["Near cooking equipment", "Prep containers", "Quick access items"]
        case .other:
            return []
        }
    }
}

import Foundation

struct InventorySummary: Codable {
    let globalValue: Double
    let activeSites: Int
    let totalIssues: Int
    let sites: [SiteSummary]

    enum CodingKeys: String, CodingKey {
        case globalValue = "global_value"
        case activeSites = "active_sites"
        case totalIssues = "total_issues"
        case sites
    }
}

struct SiteSummary: Codable, Identifiable {
    var id: String { site }

    let site: String
    let latestTotal: Double
    let deltaPct: Double
    let issueCount: Int
    let lastUpdated: String
    let healthScore: Int
    let healthStatus: String
    let roomFlagCount: Int

    enum CodingKeys: String, CodingKey {
        case site
        case latestTotal = "latest_total"
        case deltaPct = "delta_pct"
        case issueCount = "issue_count"
        case lastUpdated = "last_updated"
        case healthScore = "health_score"
        case healthStatus = "health_status"
        case roomFlagCount = "room_flag_count"
    }
}

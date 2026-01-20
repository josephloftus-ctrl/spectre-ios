import Foundation

struct HistoryResponse: Codable {
    let snapshots: [HistorySnapshot]
    let trends: TrendData?
}

struct HistorySnapshot: Codable, Identifiable {
    var id: String { date }
    let date: String
    let totalValue: Double
    let siteCount: Int
    let flagCount: Int
    let healthScore: Double
}

struct TrendData: Codable {
    let valueChange: Double
    let valueChangePercent: Double
    let flagChange: Int
    let healthChange: Double
    let movers: [Mover]
}

struct Mover: Codable, Identifiable {
    var id: String { itemName }
    let itemName: String
    let siteName: String
    let changePercent: Double
    let direction: String
}

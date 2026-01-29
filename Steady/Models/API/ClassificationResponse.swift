import Foundation

struct ClassificationResponse: Codable {
    let siteId: String
    let items: [ItemClassification]
    let summary: ClassificationSummary
    let lastCalculated: String?

    enum CodingKeys: String, CodingKey {
        case siteId = "site_id"
        case items
        case summary
        case lastCalculated = "last_calculated"
    }
}

struct ItemClassification: Codable, Identifiable {
    var id: String { sku }

    let sku: String
    let abcClass: String?
    let xyzClass: String?
    let combinedClass: String?
    let totalValue: Double?
    let avgQuantity: Double?
    let cvScore: Double?
    let weeksOfData: Int?

    enum CodingKeys: String, CodingKey {
        case sku
        case abcClass = "abc_class"
        case xyzClass = "xyz_class"
        case combinedClass = "combined_class"
        case totalValue = "total_value"
        case avgQuantity = "avg_quantity"
        case cvScore = "cv_score"
        case weeksOfData = "weeks_of_data"
    }
}

struct ClassificationSummary: Codable {
    let aCount: Int
    let bCount: Int
    let cCount: Int
    let unclassifiedCount: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case aCount = "a_count"
        case bCount = "b_count"
        case cCount = "c_count"
        case unclassifiedCount = "unclassified_count"
        case total
    }
}

import Foundation

/// A canon item template for quick zone setup
struct CanonItem: Identifiable, Hashable {
    let id: String
    let name: String
    let unit: String
    let category: String
    let defaultPar: Double

    func toZCItem() -> ZCItem {
        ZCItem(name: name, unit: unit, category: category, canonItemId: id)
    }
}

/// A zone template with default items
struct ZoneTemplate: Identifiable {
    let id: String
    let zoneType: ZoneType
    let subType: String  // e.g., "Proteins", "Dairy", "Produce"
    let code: String     // e.g., "WIC-01"
    let name: String     // e.g., "Walk-in Cooler - Proteins"
    let shelfPosition: String?  // e.g., "BOTTOM" for food safety
    let items: [CanonItem]

    var fullName: String {
        "\(zoneType.displayName) - \(subType)"
    }
}

/// The Canon system - built-in institutional knowledge for food service
enum Canon {

    // MARK: - Zone Templates

    /// All available zone templates
    static let zoneTemplates: [ZoneTemplate] = [
        walkInCoolerProteins,
        walkInCoolerDairy,
        walkInCoolerProduce,
        walkInCoolerPrep,
        walkInFreezerProteins,
        walkInFreezerOther,
        dryStorageCannedOils,
        dryStorageGrainsBaking,
        dryStoragePaperChem,
        reachInCoolerLine,
        reachInFreezerLine
    ]

    /// Get templates for a specific zone type
    static func templates(for zoneType: ZoneType) -> [ZoneTemplate] {
        zoneTemplates.filter { $0.zoneType == zoneType }
    }

    /// Default templates suggested when a zone type is detected
    static func defaultTemplates(for zoneType: ZoneType) -> [ZoneTemplate] {
        switch zoneType {
        case .walkInCooler:
            return [walkInCoolerProteins, walkInCoolerDairy, walkInCoolerProduce, walkInCoolerPrep]
        case .walkInFreezer:
            return [walkInFreezerProteins, walkInFreezerOther]
        case .dryStorage:
            return [dryStorageCannedOils, dryStorageGrainsBaking, dryStoragePaperChem]
        case .reachInCooler:
            return [reachInCoolerLine]
        case .reachInFreezer:
            return [reachInFreezerLine]
        case .lineStation, .other:
            return []
        }
    }

    // MARK: - Walk-in Cooler Templates

    static let walkInCoolerProteins = ZoneTemplate(
        id: "wic-proteins",
        zoneType: .walkInCooler,
        subType: "Proteins",
        code: "WIC-01",
        name: "Walk-in Cooler - Proteins",
        shelfPosition: "BOTTOM (food safety - prevents drip contamination)",
        items: [
            CanonItem(id: "wic-p-01", name: "Chicken Breast, raw", unit: "case", category: "Protein", defaultPar: 4),
            CanonItem(id: "wic-p-02", name: "Chicken Thighs, raw", unit: "case", category: "Protein", defaultPar: 2),
            CanonItem(id: "wic-p-03", name: "Ground Beef, 80/20", unit: "case", category: "Protein", defaultPar: 4),
            CanonItem(id: "wic-p-04", name: "Ground Turkey", unit: "case", category: "Protein", defaultPar: 2),
            CanonItem(id: "wic-p-05", name: "Beef Strip Steak", unit: "lb", category: "Protein", defaultPar: 10),
            CanonItem(id: "wic-p-06", name: "Pork Loin", unit: "lb", category: "Protein", defaultPar: 8),
            CanonItem(id: "wic-p-07", name: "Salmon Fillet", unit: "lb", category: "Protein", defaultPar: 6),
            CanonItem(id: "wic-p-08", name: "Shrimp, 16/20", unit: "bag", category: "Protein", defaultPar: 4),
            CanonItem(id: "wic-p-09", name: "Turkey Breast, deli", unit: "lb", category: "Protein", defaultPar: 5),
            CanonItem(id: "wic-p-10", name: "Ham, deli", unit: "lb", category: "Protein", defaultPar: 5),
            CanonItem(id: "wic-p-11", name: "Bacon, sliced", unit: "case", category: "Protein", defaultPar: 2)
        ]
    )

    static let walkInCoolerDairy = ZoneTemplate(
        id: "wic-dairy",
        zoneType: .walkInCooler,
        subType: "Dairy",
        code: "WIC-02",
        name: "Walk-in Cooler - Dairy",
        shelfPosition: "MIDDLE",
        items: [
            CanonItem(id: "wic-d-01", name: "Milk, whole", unit: "gal", category: "Dairy", defaultPar: 4),
            CanonItem(id: "wic-d-02", name: "Milk, 2%", unit: "gal", category: "Dairy", defaultPar: 4),
            CanonItem(id: "wic-d-03", name: "Half and Half", unit: "qt", category: "Dairy", defaultPar: 6),
            CanonItem(id: "wic-d-04", name: "Heavy Cream", unit: "qt", category: "Dairy", defaultPar: 4),
            CanonItem(id: "wic-d-05", name: "Butter, salted", unit: "lb", category: "Dairy", defaultPar: 8),
            CanonItem(id: "wic-d-06", name: "Eggs, fresh", unit: "case", category: "Dairy", defaultPar: 2),
            CanonItem(id: "wic-d-07", name: "Shredded Cheddar", unit: "bag", category: "Dairy", defaultPar: 4),
            CanonItem(id: "wic-d-08", name: "Shredded Mozzarella", unit: "bag", category: "Dairy", defaultPar: 4),
            CanonItem(id: "wic-d-09", name: "American Cheese, sliced", unit: "case", category: "Dairy", defaultPar: 2),
            CanonItem(id: "wic-d-10", name: "Cream Cheese", unit: "lb", category: "Dairy", defaultPar: 4),
            CanonItem(id: "wic-d-11", name: "Sour Cream", unit: "container", category: "Dairy", defaultPar: 4),
            CanonItem(id: "wic-d-12", name: "Parmesan, grated", unit: "container", category: "Dairy", defaultPar: 2)
        ]
    )

    static let walkInCoolerProduce = ZoneTemplate(
        id: "wic-produce",
        zoneType: .walkInCooler,
        subType: "Produce",
        code: "WIC-03",
        name: "Walk-in Cooler - Produce",
        shelfPosition: "MIDDLE-HIGH",
        items: [
            CanonItem(id: "wic-pr-01", name: "Lettuce, romaine", unit: "case", category: "Produce", defaultPar: 2),
            CanonItem(id: "wic-pr-02", name: "Mixed Greens", unit: "bag", category: "Produce", defaultPar: 6),
            CanonItem(id: "wic-pr-03", name: "Spinach, baby", unit: "bag", category: "Produce", defaultPar: 4),
            CanonItem(id: "wic-pr-04", name: "Tomatoes, slicing", unit: "case", category: "Produce", defaultPar: 2),
            CanonItem(id: "wic-pr-05", name: "Tomatoes, grape", unit: "container", category: "Produce", defaultPar: 4),
            CanonItem(id: "wic-pr-06", name: "Onions, yellow", unit: "bag", category: "Produce", defaultPar: 2),
            CanonItem(id: "wic-pr-07", name: "Onions, diced prep", unit: "container", category: "Produce", defaultPar: 4),
            CanonItem(id: "wic-pr-08", name: "Peppers, bell mixed", unit: "case", category: "Produce", defaultPar: 1),
            CanonItem(id: "wic-pr-09", name: "Cucumbers", unit: "case", category: "Produce", defaultPar: 1),
            CanonItem(id: "wic-pr-10", name: "Carrots, whole", unit: "bag", category: "Produce", defaultPar: 2),
            CanonItem(id: "wic-pr-11", name: "Carrots, shredded", unit: "bag", category: "Produce", defaultPar: 4),
            CanonItem(id: "wic-pr-12", name: "Celery", unit: "bunch", category: "Produce", defaultPar: 4),
            CanonItem(id: "wic-pr-13", name: "Lemons", unit: "each", category: "Produce", defaultPar: 12),
            CanonItem(id: "wic-pr-14", name: "Limes", unit: "each", category: "Produce", defaultPar: 12),
            CanonItem(id: "wic-pr-15", name: "Garlic, peeled", unit: "container", category: "Produce", defaultPar: 2),
            CanonItem(id: "wic-pr-16", name: "Herbs, fresh mixed", unit: "bunch", category: "Produce", defaultPar: 4)
        ]
    )

    static let walkInCoolerPrep = ZoneTemplate(
        id: "wic-prep",
        zoneType: .walkInCooler,
        subType: "Prep/RTE",
        code: "WIC-04",
        name: "Walk-in Cooler - Prep/RTE",
        shelfPosition: "TOP (ready-to-eat, lowest contamination risk)",
        items: [
            CanonItem(id: "wic-rte-01", name: "Chicken, diced cooked", unit: "container", category: "Prep", defaultPar: 4),
            CanonItem(id: "wic-rte-02", name: "Beef, sliced cooked", unit: "container", category: "Prep", defaultPar: 2),
            CanonItem(id: "wic-rte-03", name: "House Dressing", unit: "container", category: "Prep", defaultPar: 4),
            CanonItem(id: "wic-rte-04", name: "Ranch Dressing", unit: "container", category: "Prep", defaultPar: 4),
            CanonItem(id: "wic-rte-05", name: "Soup of Day", unit: "container", category: "Prep", defaultPar: 2),
            CanonItem(id: "wic-rte-06", name: "Sauce, marinara", unit: "container", category: "Prep", defaultPar: 4),
            CanonItem(id: "wic-rte-07", name: "Sauce, alfredo", unit: "container", category: "Prep", defaultPar: 2),
            CanonItem(id: "wic-rte-08", name: "Guacamole", unit: "container", category: "Prep", defaultPar: 2),
            CanonItem(id: "wic-rte-09", name: "Hummus", unit: "container", category: "Prep", defaultPar: 2),
            CanonItem(id: "wic-rte-10", name: "Salsa, house", unit: "container", category: "Prep", defaultPar: 4)
        ]
    )

    // MARK: - Walk-in Freezer Templates

    static let walkInFreezerProteins = ZoneTemplate(
        id: "wif-proteins",
        zoneType: .walkInFreezer,
        subType: "Proteins",
        code: "WIF-01",
        name: "Walk-in Freezer - Proteins",
        shelfPosition: nil,
        items: [
            CanonItem(id: "wif-p-01", name: "Chicken Breast, frozen", unit: "case", category: "Protein", defaultPar: 2),
            CanonItem(id: "wif-p-02", name: "Beef Patties, frozen", unit: "case", category: "Protein", defaultPar: 2),
            CanonItem(id: "wif-p-03", name: "Fish Fillets, frozen", unit: "case", category: "Protein", defaultPar: 2),
            CanonItem(id: "wif-p-04", name: "Shrimp, frozen", unit: "bag", category: "Protein", defaultPar: 4),
            CanonItem(id: "wif-p-05", name: "Chicken Tenders, breaded", unit: "case", category: "Protein", defaultPar: 2),
            CanonItem(id: "wif-p-06", name: "Meatballs, frozen", unit: "bag", category: "Protein", defaultPar: 4)
        ]
    )

    static let walkInFreezerOther = ZoneTemplate(
        id: "wif-other",
        zoneType: .walkInFreezer,
        subType: "Other",
        code: "WIF-02",
        name: "Walk-in Freezer - Other",
        shelfPosition: nil,
        items: [
            CanonItem(id: "wif-o-01", name: "French Fries", unit: "case", category: "Frozen", defaultPar: 4),
            CanonItem(id: "wif-o-02", name: "Vegetables, mixed frozen", unit: "bag", category: "Frozen", defaultPar: 6),
            CanonItem(id: "wif-o-03", name: "Bread, loaves", unit: "case", category: "Frozen", defaultPar: 2),
            CanonItem(id: "wif-o-04", name: "Burger Buns", unit: "case", category: "Frozen", defaultPar: 2),
            CanonItem(id: "wif-o-05", name: "Pie Shells", unit: "case", category: "Frozen", defaultPar: 1),
            CanonItem(id: "wif-o-06", name: "Ice Cream, vanilla", unit: "container", category: "Frozen", defaultPar: 2)
        ]
    )

    // MARK: - Dry Storage Templates

    static let dryStorageCannedOils = ZoneTemplate(
        id: "dry-canned",
        zoneType: .dryStorage,
        subType: "Canned/Oils",
        code: "DRY-01",
        name: "Dry Storage - Canned/Oils",
        shelfPosition: nil,
        items: [
            CanonItem(id: "dry-c-01", name: "Diced Tomatoes, #10", unit: "case", category: "Canned", defaultPar: 2),
            CanonItem(id: "dry-c-02", name: "Crushed Tomatoes, #10", unit: "case", category: "Canned", defaultPar: 2),
            CanonItem(id: "dry-c-03", name: "Tomato Paste, #10", unit: "case", category: "Canned", defaultPar: 1),
            CanonItem(id: "dry-c-04", name: "Black Beans, #10", unit: "case", category: "Canned", defaultPar: 2),
            CanonItem(id: "dry-c-05", name: "Kidney Beans, #10", unit: "case", category: "Canned", defaultPar: 1),
            CanonItem(id: "dry-c-06", name: "Chickpeas, #10", unit: "case", category: "Canned", defaultPar: 1),
            CanonItem(id: "dry-c-07", name: "Chicken Stock", unit: "case", category: "Canned", defaultPar: 2),
            CanonItem(id: "dry-c-08", name: "Beef Stock", unit: "case", category: "Canned", defaultPar: 1),
            CanonItem(id: "dry-c-09", name: "Vegetable Stock", unit: "case", category: "Canned", defaultPar: 1),
            CanonItem(id: "dry-c-10", name: "Olive Oil", unit: "gal", category: "Oil", defaultPar: 2),
            CanonItem(id: "dry-c-11", name: "Canola Oil", unit: "gal", category: "Oil", defaultPar: 4),
            CanonItem(id: "dry-c-12", name: "Vegetable Oil", unit: "gal", category: "Oil", defaultPar: 2)
        ]
    )

    static let dryStorageGrainsBaking = ZoneTemplate(
        id: "dry-grains",
        zoneType: .dryStorage,
        subType: "Grains/Baking",
        code: "DRY-02",
        name: "Dry Storage - Grains/Baking",
        shelfPosition: nil,
        items: [
            CanonItem(id: "dry-g-01", name: "Pasta, penne", unit: "case", category: "Grain", defaultPar: 2),
            CanonItem(id: "dry-g-02", name: "Pasta, spaghetti", unit: "case", category: "Grain", defaultPar: 2),
            CanonItem(id: "dry-g-03", name: "Rice, long grain", unit: "bag", category: "Grain", defaultPar: 2),
            CanonItem(id: "dry-g-04", name: "Rice, brown", unit: "bag", category: "Grain", defaultPar: 1),
            CanonItem(id: "dry-g-05", name: "Quinoa", unit: "bag", category: "Grain", defaultPar: 1),
            CanonItem(id: "dry-g-06", name: "AP Flour", unit: "bag", category: "Baking", defaultPar: 2),
            CanonItem(id: "dry-g-07", name: "Bread Flour", unit: "bag", category: "Baking", defaultPar: 1),
            CanonItem(id: "dry-g-08", name: "Sugar, granulated", unit: "bag", category: "Baking", defaultPar: 2),
            CanonItem(id: "dry-g-09", name: "Sugar, brown", unit: "bag", category: "Baking", defaultPar: 1),
            CanonItem(id: "dry-g-10", name: "Baking Powder", unit: "container", category: "Baking", defaultPar: 1),
            CanonItem(id: "dry-g-11", name: "Baking Soda", unit: "box", category: "Baking", defaultPar: 1)
        ]
    )

    static let dryStoragePaperChem = ZoneTemplate(
        id: "dry-paper",
        zoneType: .dryStorage,
        subType: "Paper/Chem",
        code: "DRY-03",
        name: "Dry Storage - Paper/Chem",
        shelfPosition: nil,
        items: [
            CanonItem(id: "dry-p-01", name: "To-go Containers, 8oz", unit: "case", category: "Paper", defaultPar: 2),
            CanonItem(id: "dry-p-02", name: "To-go Containers, 16oz", unit: "case", category: "Paper", defaultPar: 2),
            CanonItem(id: "dry-p-03", name: "To-go Containers, 32oz", unit: "case", category: "Paper", defaultPar: 1),
            CanonItem(id: "dry-p-04", name: "Napkins", unit: "case", category: "Paper", defaultPar: 2),
            CanonItem(id: "dry-p-05", name: "Paper Towels", unit: "case", category: "Paper", defaultPar: 2),
            CanonItem(id: "dry-p-06", name: "Gloves, M", unit: "case", category: "Supply", defaultPar: 2),
            CanonItem(id: "dry-p-07", name: "Gloves, L", unit: "case", category: "Supply", defaultPar: 2),
            CanonItem(id: "dry-p-08", name: "Degreaser", unit: "gal", category: "Chem", defaultPar: 2),
            CanonItem(id: "dry-p-09", name: "Sanitizer", unit: "gal", category: "Chem", defaultPar: 4),
            CanonItem(id: "dry-p-10", name: "Dish Soap", unit: "gal", category: "Chem", defaultPar: 2)
        ]
    )

    // MARK: - Reach-in Templates

    static let reachInCoolerLine = ZoneTemplate(
        id: "ric-line",
        zoneType: .reachInCooler,
        subType: "Line",
        code: "RIC-01",
        name: "Reach-in Cooler - Line",
        shelfPosition: nil,
        items: []  // Typically site-specific based on menu
    )

    static let reachInFreezerLine = ZoneTemplate(
        id: "rif-line",
        zoneType: .reachInFreezer,
        subType: "Line",
        code: "RIF-01",
        name: "Reach-in Freezer - Line",
        shelfPosition: nil,
        items: []  // Typically site-specific based on menu
    )
}

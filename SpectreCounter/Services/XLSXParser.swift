import Foundation
import CoreXLSX

enum XLSXParserError: LocalizedError {
    case fileNotFound
    case invalidFormat
    case missingRequiredColumns([String])
    case noDataRows

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "File not found"
        case .invalidFormat:
            return "Invalid XLSX format"
        case .missingRequiredColumns(let columns):
            return "Missing required columns: \(columns.joined(separator: ", "))"
        case .noDataRows:
            return "No data rows found in worksheet"
        }
    }
}

struct ParseResult {
    let items: [InventoryItem]
    let quantityColumn: String  // Column letter (e.g., "E")
}

struct XLSXParser {

    // Expected column headers (MOG template)
    private static let columnMap: [String: String] = [
        "Item Description": "itemDescription",
        "Dist # *": "distNumber",
        "Dist #": "distNumber",
        "Cust # *": "custNumber",
        "Cust #": "custNumber",
        "Quantity": "quantity",
        "UOM": "uom",
        "Location": "location",
        "Area": "area",
        "Place": "place"
    ]

    static func parse(url: URL) throws -> ParseResult {
        guard let file = XLSXFile(filepath: url.path) else {
            throw XLSXParserError.fileNotFound
        }

        let workbookPaths = try file.parseWorkbooks()
        guard let workbook = workbookPaths.first,
              let sheetName = try file.parseWorksheetPathsAndNames(workbook: workbook).first?.name,
              let worksheetPath = try file.parseWorksheetPathsAndNames(workbook: workbook).first?.path,
              let worksheet = try? file.parseWorksheet(at: worksheetPath) else {
            throw XLSXParserError.invalidFormat
        }

        let sharedStrings = try? file.parseSharedStrings()

        guard let rows = worksheet.data?.rows, !rows.isEmpty else {
            throw XLSXParserError.noDataRows
        }

        // Parse header row to find column indices and letters
        let headerRow = rows[0]
        var columnIndices: [String: Int] = [:]
        var columnLetters: [String: String] = [:]

        for cell in headerRow.cells {
            if let value = cell.stringValue(sharedStrings) {
                if let mappedName = columnMap[value] {
                    let colRef = cell.reference.column
                    columnIndices[mappedName] = colRef.index
                    columnLetters[mappedName] = colRef.value
                }
            }
        }

        // Verify required columns (including quantity for export)
        let required = ["itemDescription", "distNumber", "quantity"]
        let missing = required.filter { columnIndices[$0] == nil }
        if !missing.isEmpty {
            throw XLSXParserError.missingRequiredColumns(missing)
        }

        let quantityColumn = columnLetters["quantity"]!

        // Parse data rows
        var items: [InventoryItem] = []

        for (index, row) in rows.dropFirst().enumerated() {
            let cellValues = parseCellValues(row: row, sharedStrings: sharedStrings)

            let itemDescription = getValue(cellValues, columnIndices, "itemDescription") ?? ""
            let distNumber = getValue(cellValues, columnIndices, "distNumber") ?? ""

            // Skip empty rows
            if itemDescription.isEmpty && distNumber.isEmpty {
                continue
            }

            let item = InventoryItem(
                itemDescription: itemDescription,
                distNumber: distNumber,
                custNumber: getValue(cellValues, columnIndices, "custNumber"),
                uom: getValue(cellValues, columnIndices, "uom") ?? "",
                location: getValue(cellValues, columnIndices, "location") ?? "",
                area: getValue(cellValues, columnIndices, "area") ?? "",
                place: getValue(cellValues, columnIndices, "place") ?? "",
                count: Int(getValue(cellValues, columnIndices, "quantity") ?? "") ?? 0,
                rowIndex: index + 2 // +2 for 1-indexed and header row
            )

            items.append(item)
        }

        if items.isEmpty {
            throw XLSXParserError.noDataRows
        }

        return ParseResult(items: items, quantityColumn: quantityColumn)
    }

    private static func parseCellValues(row: Row, sharedStrings: SharedStrings?) -> [Int: String] {
        var values: [Int: String] = [:]
        for cell in row.cells {
            let colRef = cell.reference.column
            if let value = cell.stringValue(sharedStrings) {
                values[colRef.index] = value
            }
        }
        return values
    }

    private static func getValue(_ cellValues: [Int: String], _ indices: [String: Int], _ key: String) -> String? {
        guard let colIndex = indices[key] else { return nil }
        return cellValues[colIndex]
    }
}

extension Cell {
    func stringValue(_ sharedStrings: SharedStrings?) -> String? {
        if let inlineString = self.inlineString?.text {
            return inlineString
        }
        if let sharedStrings = sharedStrings,
           let value = self.value,
           let index = Int(value) {
            return sharedStrings.items[index].text
        }
        return self.value
    }
}

extension ColumnReference {
    var index: Int {
        var result = 0
        for char in self.value.uppercased() {
            result = result * 26 + Int(char.asciiValue! - Character("A").asciiValue!) + 1
        }
        return result - 1
    }
}

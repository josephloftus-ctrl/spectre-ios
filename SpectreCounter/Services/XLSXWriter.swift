import Foundation

enum XLSXWriterError: LocalizedError {
    case templateNotFound
    case writeFailed

    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "Original template not found"
        case .writeFailed:
            return "Failed to write XLSX file"
        }
    }
}

struct XLSXWriter {

    /// Simple CSV export (reliable, MOG accepts CSV)
    static func exportCSV(items: [InventoryItem]) throws -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let timestamp = dateFormatter.string(from: Date())
        let outputFilename = "Inventory_\(timestamp).csv"

        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(outputFilename)

        var csv = "Item Description,Dist #,Quantity,UOM,Location,Area,Place\n"

        for item in items.sorted(by: { $0.rowIndex < $1.rowIndex }) {
            let row = [
                escapeCSV(item.itemDescription),
                escapeCSV(item.distNumber),
                String(item.count),
                escapeCSV(item.uom),
                escapeCSV(item.location),
                escapeCSV(item.area),
                escapeCSV(item.place)
            ].joined(separator: ",")
            csv += row + "\n"
        }

        try csv.write(to: outputURL, atomically: true, encoding: .utf8)
        return outputURL
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

import Foundation
import ZIPFoundation

enum XLSXWriterError: LocalizedError {
    case templateNotFound
    case invalidTemplate
    case writeFailed(String)

    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "Original template not found"
        case .invalidTemplate:
            return "Template is not a valid XLSX file"
        case .writeFailed(let reason):
            return "Failed to write XLSX: \(reason)"
        }
    }
}

struct XLSXWriter {

    /// Export by modifying the original template - only updates quantity cells
    static func export(session: CountSession) throws -> URL {
        // Verify template exists
        let templateURL = URL(fileURLWithPath: session.templatePath)
        guard FileManager.default.fileExists(atPath: templateURL.path) else {
            throw XLSXWriterError.templateNotFound
        }

        // Create output file
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HHmm"
        let timestamp = dateFormatter.string(from: Date())
        let outputFilename = "Counted_\(timestamp).xlsx"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(outputFilename)

        // Remove existing output if present
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        // Copy template to output
        try FileManager.default.copyItem(at: templateURL, to: outputURL)

        // Build map of row -> count value
        var countsByRow: [Int: Int] = [:]
        for item in session.items {
            countsByRow[item.rowIndex] = item.count
        }

        // Modify the worksheet XML inside the XLSX (which is a ZIP)
        try modifyWorksheet(
            xlsxURL: outputURL,
            quantityColumn: session.quantityColumn,
            countsByRow: countsByRow
        )

        return outputURL
    }

    private static func modifyWorksheet(xlsxURL: URL, quantityColumn: String, countsByRow: [Int: Int]) throws {
        // XLSX is a ZIP file - we need to extract, modify, and repack
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
        }

        // Extract XLSX
        try FileManager.default.unzipItem(at: xlsxURL, to: tempDir)

        // Find worksheet file (usually xl/worksheets/sheet1.xml)
        let worksheetPath = tempDir.appendingPathComponent("xl/worksheets/sheet1.xml")
        guard FileManager.default.fileExists(atPath: worksheetPath.path) else {
            throw XLSXWriterError.invalidTemplate
        }

        // Read and modify worksheet XML
        var xmlContent = try String(contentsOf: worksheetPath, encoding: .utf8)

        // Update each quantity cell
        for (rowIndex, count) in countsByRow {
            let cellRef = "\(quantityColumn)\(rowIndex)"  // e.g., "E2", "E3"
            xmlContent = updateCellValue(in: xmlContent, cellRef: cellRef, newValue: String(count))
        }

        // Write modified XML
        try xmlContent.write(to: worksheetPath, atomically: true, encoding: .utf8)

        // Remove original XLSX and repack
        try FileManager.default.removeItem(at: xlsxURL)

        // Create new ZIP with modified contents
        try FileManager.default.zipItem(at: tempDir, to: xlsxURL)
    }

    private static func updateCellValue(in xml: String, cellRef: String, newValue: String) -> String {
        // Cell format in XLSX: <c r="E2" ...><v>value</v></c>
        // We need to find the cell and update its value

        // Pattern to match the cell with this reference
        // Cell might have attributes like t="s" (shared string) or t="n" (number)
        let cellPattern = #"(<c[^>]*\sr="\#(cellRef)"[^>]*>)(.*?)(</c>)"#

        guard let regex = try? NSRegularExpression(pattern: cellPattern, options: [.dotMatchesLineSeparators]) else {
            return xml
        }

        let range = NSRange(xml.startIndex..., in: xml)

        if let match = regex.firstMatch(in: xml, options: [], range: range) {
            // Found the cell - replace it with a simple numeric cell
            let newCell = "<c r=\"\(cellRef)\"><v>\(newValue)</v></c>"
            var result = xml
            if let matchRange = Range(match.range, in: xml) {
                result.replaceSubrange(matchRange, with: newCell)
            }
            return result
        } else {
            // Cell doesn't exist - need to insert it into the correct row
            return insertCell(in: xml, cellRef: cellRef, value: newValue)
        }
    }

    private static func insertCell(in xml: String, cellRef: String, value: String) -> String {
        // Extract row number from cell reference (e.g., "E2" -> "2")
        let rowNum = String(cellRef.drop(while: { $0.isLetter }))

        // Find the row element and insert the cell
        let rowPattern = #"(<row[^>]*\sr="\#(rowNum)"[^>]*>)(.*?)(</row>)"#

        guard let regex = try? NSRegularExpression(pattern: rowPattern, options: [.dotMatchesLineSeparators]) else {
            return xml
        }

        let range = NSRange(xml.startIndex..., in: xml)

        if let match = regex.firstMatch(in: xml, options: [], range: range) {
            var result = xml
            if let closeTagRange = Range(match.range(at: 4), in: xml) {
                // Insert new cell before </row>
                let newCell = "<c r=\"\(cellRef)\"><v>\(value)</v></c>"
                result.insert(contentsOf: newCell, at: closeTagRange.lowerBound)
            }
            return result
        }

        return xml
    }
}

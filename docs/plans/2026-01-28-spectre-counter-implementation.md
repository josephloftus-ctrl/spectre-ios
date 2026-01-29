# Spectre Counter Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an iOS app that imports OrderMaestro inventory worksheets, provides offline counting with swipe gestures, and exports MOG-compatible XLSX files.

**Architecture:** SwiftUI app with three views (Import → Count → Export). CoreXLSX for parsing/writing XLSX. SwiftData for session persistence. No network calls - fully offline.

**Tech Stack:** Swift, SwiftUI, CoreXLSX, SwiftData, iOS 17+

---

## Task 1: Project Setup

**Files:**
- Create: `SpectreCounter/` Xcode project structure
- Create: `SpectreCounter/SpectreCounterApp.swift`

**Step 1: Create Xcode project**

Create new iOS App project in Xcode:
- Product Name: SpectreCounter
- Organization: com.spectre
- Interface: SwiftUI
- Language: Swift
- Minimum Deployment: iOS 17.0

**Step 2: Add CoreXLSX dependency**

In Xcode: File → Add Package Dependencies
URL: `https://github.com/CoreOffice/CoreXLSX`
Version: Up to Next Major (0.14.0+)

**Step 3: Verify project builds**

Run: Cmd+B in Xcode
Expected: Build Succeeded

**Step 4: Commit**

```bash
git add SpectreCounter/
git commit -m "feat: initialize SpectreCounter iOS project with CoreXLSX"
```

---

## Task 2: Data Models

**Files:**
- Create: `SpectreCounter/Models/InventoryItem.swift`
- Create: `SpectreCounter/Models/CountSession.swift`

**Step 1: Create InventoryItem model**

```swift
// SpectreCounter/Models/InventoryItem.swift
import Foundation
import SwiftData

@Model
final class InventoryItem {
    var id: UUID
    var itemDescription: String
    var distNumber: String
    var custNumber: String?
    var uom: String
    var location: String
    var area: String
    var place: String

    // Counting state
    var count: Int
    var isCounted: Bool
    var countedAt: Date?

    // Original row index for export
    var rowIndex: Int

    init(
        itemDescription: String,
        distNumber: String,
        custNumber: String? = nil,
        uom: String,
        location: String,
        area: String,
        place: String,
        count: Int = 0,
        rowIndex: Int
    ) {
        self.id = UUID()
        self.itemDescription = itemDescription
        self.distNumber = distNumber
        self.custNumber = custNumber
        self.uom = uom
        self.location = location
        self.area = area
        self.place = place
        self.count = count
        self.isCounted = false
        self.countedAt = nil
        self.rowIndex = rowIndex
    }

    var locationKey: String {
        [location, area, place].filter { !$0.isEmpty }.joined(separator: " > ")
    }
}
```

**Step 2: Create CountSession model**

```swift
// SpectreCounter/Models/CountSession.swift
import Foundation
import SwiftData

@Model
final class CountSession {
    var id: UUID
    var importedAt: Date
    var sourceFilename: String

    @Relationship(deleteRule: .cascade)
    var items: [InventoryItem]

    init(sourceFilename: String) {
        self.id = UUID()
        self.importedAt = Date()
        self.sourceFilename = sourceFilename
        self.items = []
    }

    var countedCount: Int {
        items.filter { $0.isCounted }.count
    }

    var totalCount: Int {
        items.count
    }
}
```

**Step 3: Verify models compile**

Run: Cmd+B
Expected: Build Succeeded

**Step 4: Commit**

```bash
git add SpectreCounter/Models/
git commit -m "feat: add InventoryItem and CountSession data models"
```

---

## Task 3: XLSX Parser Service

**Files:**
- Create: `SpectreCounter/Services/XLSXParser.swift`

**Step 1: Create parser service**

```swift
// SpectreCounter/Services/XLSXParser.swift
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

    static func parse(url: URL) throws -> [InventoryItem] {
        guard let file = XLSXFile(filepath: url.path) else {
            throw XLSXParserError.fileNotFound
        }

        guard let workbook = try? file.parseWorkbooks().first,
              let sheetName = workbook.sheets?.items.first?.name,
              let worksheet = try? file.parseWorksheet(at: sheetName) else {
            throw XLSXParserError.invalidFormat
        }

        let sharedStrings = try? file.parseSharedStrings()

        guard let rows = worksheet.data?.rows, !rows.isEmpty else {
            throw XLSXParserError.noDataRows
        }

        // Parse header row to find column indices
        let headerRow = rows[0]
        var columnIndices: [String: Int] = [:]

        for cell in headerRow.cells {
            if let value = cell.stringValue(sharedStrings) {
                if let mappedName = columnMap[value] {
                    if let colRef = cell.reference.column {
                        columnIndices[mappedName] = colRef.index
                    }
                }
            }
        }

        // Verify required columns
        let required = ["itemDescription", "distNumber"]
        let missing = required.filter { columnIndices[$0] == nil }
        if !missing.isEmpty {
            throw XLSXParserError.missingRequiredColumns(missing)
        }

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

        return items
    }

    private static func parseCellValues(row: Row, sharedStrings: SharedStrings?) -> [Int: String] {
        var values: [Int: String] = [:]
        for cell in row.cells {
            if let colRef = cell.reference.column,
               let value = cell.stringValue(sharedStrings) {
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
```

**Step 2: Verify parser compiles**

Run: Cmd+B
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add SpectreCounter/Services/XLSXParser.swift
git commit -m "feat: add XLSX parser service for MOG template import"
```

---

## Task 4: XLSX Writer Service

**Files:**
- Create: `SpectreCounter/Services/XLSXWriter.swift`

**Step 1: Create writer service**

```swift
// SpectreCounter/Services/XLSXWriter.swift
import Foundation
import CoreXLSX

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
```

**Step 2: Verify writer compiles**

Run: Cmd+B
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add SpectreCounter/Services/XLSXWriter.swift
git commit -m "feat: add CSV writer service for export"
```

---

## Task 5: Import View

**Files:**
- Create: `SpectreCounter/Views/ImportView.swift`

**Step 1: Create import view**

```swift
// SpectreCounter/Views/ImportView.swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [CountSession]

    @State private var showFilePicker = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false

    @Binding var activeSession: CountSession?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)

                Text("Spectre Counter")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                if let session = sessions.first {
                    VStack(spacing: 8) {
                        Text("Previous session available")
                            .foregroundStyle(.secondary)
                        Text(session.sourceFilename)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Continue Counting") {
                            activeSession = session
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Import New Worksheet") {
                            showFilePicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("No inventory loaded")
                            .foregroundStyle(.secondary)

                        Button {
                            showFilePicker = true
                        } label: {
                            Label("Import Worksheet", systemImage: "square.and.arrow.down")
                                .frame(minWidth: 200)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }

                Text("Accepts .xlsx files from\nOrderMaestro inventory worksheet export")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("")
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [UTType(filenameExtension: "xlsx")!],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView("Importing...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importFile(url: url)
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func importFile(url: URL) {
        isLoading = true

        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Cannot access file"
            showError = true
            isLoading = false
            return
        }

        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let localURL = documentsURL.appendingPathComponent("imported_\(url.lastPathComponent)")

            if FileManager.default.fileExists(atPath: localURL.path) {
                try FileManager.default.removeItem(at: localURL)
            }
            try FileManager.default.copyItem(at: url, to: localURL)

            let items = try XLSXParser.parse(url: localURL)

            for session in sessions {
                modelContext.delete(session)
            }

            let session = CountSession(sourceFilename: url.lastPathComponent)
            session.items = items
            modelContext.insert(session)

            try modelContext.save()

            activeSession = session
            isLoading = false

        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }
}
```

**Step 2: Verify view compiles**

Run: Cmd+B
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add SpectreCounter/Views/ImportView.swift
git commit -m "feat: add ImportView with file picker"
```

---

## Task 6: Item Row View with Swipe Gestures

**Files:**
- Create: `SpectreCounter/Views/ItemRowView.swift`

**Step 1: Create item row with swipe and numpad**

```swift
// SpectreCounter/Views/ItemRowView.swift
import SwiftUI

struct ItemRowView: View {
    @Bindable var item: InventoryItem
    @State private var showNumpad = false
    @State private var dragOffset: CGFloat = 0

    private let swipeThreshold: CGFloat = 50

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemDescription)
                    .font(.body)
                    .lineLimit(2)

                Text(item.distNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(item.uom)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40)

            HStack(spacing: 12) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.secondary)
                    .opacity(dragOffset < -20 ? 1 : 0.3)

                Text("\(item.count)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(minWidth: 44)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showNumpad = true
                    }

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
                    .opacity(dragOffset > 20 ? 1 : 0.3)
            }

            if item.isCounted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(item.isCounted ? Color(.systemBackground) : Color(.systemGray6))
        .opacity(item.isCounted ? 0.7 : 1.0)
        .contentShape(Rectangle())
        .offset(x: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    withAnimation(.spring(response: 0.3)) {
                        if value.translation.width > swipeThreshold {
                            incrementCount()
                        } else if value.translation.width < -swipeThreshold {
                            decrementCount()
                        }
                        dragOffset = 0
                    }
                }
        )
        .sheet(isPresented: $showNumpad) {
            NumpadView(count: $item.count) {
                markCounted()
            }
            .presentationDetents([.height(350)])
        }
    }

    private func incrementCount() {
        item.count += 1
        markCounted()
    }

    private func decrementCount() {
        if item.count > 0 {
            item.count -= 1
        }
        markCounted()
    }

    private func markCounted() {
        if !item.isCounted {
            item.isCounted = true
            item.countedAt = Date()
        }
    }
}

struct NumpadView: View {
    @Binding var count: Int
    @Environment(\.dismiss) private var dismiss
    var onSave: () -> Void

    @State private var inputString = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Enter Count")
                .font(.headline)

            Text(inputString.isEmpty ? "0" : inputString)
                .font(.system(size: 48, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(1...9, id: \.self) { num in
                    NumpadButton(title: "\(num)") {
                        inputString += "\(num)"
                    }
                }

                NumpadButton(title: "C", color: .red) {
                    inputString = ""
                }

                NumpadButton(title: "0") {
                    inputString += "0"
                }

                NumpadButton(title: "✓", color: .green) {
                    count = Int(inputString) ?? 0
                    onSave()
                    dismiss()
                }
            }
        }
        .padding()
        .onAppear {
            inputString = count > 0 ? "\(count)" : ""
        }
    }
}

struct NumpadButton: View {
    let title: String
    var color: Color = .primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}
```

**Step 2: Verify view compiles**

Run: Cmd+B
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add SpectreCounter/Views/ItemRowView.swift
git commit -m "feat: add ItemRowView with swipe gestures and numpad"
```

---

## Task 7: Counting View

**Files:**
- Create: `SpectreCounter/Views/CountingView.swift`

**Step 1: Create counting view with grouped list**

```swift
// SpectreCounter/Views/CountingView.swift
import SwiftUI
import SwiftData

struct CountingView: View {
    @Bindable var session: CountSession
    @Binding var activeSession: CountSession?

    @State private var searchText = ""
    @State private var showUncountedOnly = false
    @State private var showExport = false

    private var filteredItems: [InventoryItem] {
        var items = session.items

        if showUncountedOnly {
            items = items.filter { !$0.isCounted }
        }

        if !searchText.isEmpty {
            items = items.filter {
                $0.itemDescription.localizedCaseInsensitiveContains(searchText) ||
                $0.distNumber.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items
    }

    private var groupedItems: [(String, [InventoryItem])] {
        let grouped = Dictionary(grouping: filteredItems) { $0.locationKey }
        return grouped.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("\(session.countedCount) of \(session.totalCount) counted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        showUncountedOnly.toggle()
                    } label: {
                        Text(showUncountedOnly ? "Show All" : "Uncounted")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))

                List {
                    ForEach(groupedItems, id: \.0) { location, items in
                        Section {
                            ForEach(items) { item in
                                ItemRowView(item: item)
                                    .listRowInsets(EdgeInsets())
                            }
                        } header: {
                            HStack {
                                Text(location.isEmpty ? "No Location" : location)
                                Spacer()
                                Text("\(items.count) items")
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $searchText, prompt: "Search items...")

                Button {
                    showExport = true
                } label: {
                    Text("Export")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding()
            }
            .navigationTitle("Count")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        activeSession = nil
                    }
                }
            }
            .sheet(isPresented: $showExport) {
                ExportView(session: session)
            }
        }
    }
}
```

**Step 2: Verify view compiles**

Run: Cmd+B
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add SpectreCounter/Views/CountingView.swift
git commit -m "feat: add CountingView with grouped list and search"
```

---

## Task 8: Export View

**Files:**
- Create: `SpectreCounter/Views/ExportView.swift`

**Step 1: Create export view with share sheet**

```swift
// SpectreCounter/Views/ExportView.swift
import SwiftUI

struct ExportView: View {
    let session: CountSession
    @Environment(\.dismiss) private var dismiss

    @State private var isExporting = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var uncountedCount: Int {
        session.totalCount - session.countedCount
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

                Text("Ready to Export")
                    .font(.title)
                    .fontWeight(.bold)

                VStack(spacing: 8) {
                    HStack {
                        Text("Items counted:")
                        Spacer()
                        Text("\(session.countedCount)")
                            .fontWeight(.semibold)
                    }

                    if uncountedCount > 0 {
                        HStack {
                            Text("Items uncounted:")
                            Spacer()
                            Text("\(uncountedCount)")
                                .fontWeight(.semibold)
                                .foregroundStyle(.orange)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                VStack(spacing: 12) {
                    Button {
                        exportFile()
                    } label: {
                        Label(uncountedCount > 0 ? "Export Anyway" : "Export", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    if uncountedCount > 0 {
                        Button("Review Uncounted") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isExporting {
                    ProgressView("Exporting...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func exportFile() {
        isExporting = true

        do {
            let url = try XLSXWriter.exportCSV(items: session.items)
            exportURL = url
            isExporting = false
            showShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
            isExporting = false
            showError = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

**Step 2: Verify view compiles**

Run: Cmd+B
Expected: Build Succeeded

**Step 3: Commit**

```bash
git add SpectreCounter/Views/ExportView.swift
git commit -m "feat: add ExportView with share sheet"
```

---

## Task 9: App Entry Point

**Files:**
- Create: `SpectreCounter/Views/ContentView.swift`
- Create: `SpectreCounter/SpectreCounterApp.swift`

**Step 1: Create content view**

```swift
// SpectreCounter/Views/ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var activeSession: CountSession?

    var body: some View {
        Group {
            if let session = activeSession {
                CountingView(session: session, activeSession: $activeSession)
            } else {
                ImportView(activeSession: $activeSession)
            }
        }
    }
}
```

**Step 2: Create app entry point**

```swift
// SpectreCounter/SpectreCounterApp.swift
import SwiftUI
import SwiftData

@main
struct SpectreCounterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CountSession.self,
            InventoryItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Step 3: Verify app builds and runs**

Run: Cmd+R in Xcode
Expected: App launches showing Import view

**Step 4: Commit**

```bash
git add SpectreCounter/
git commit -m "feat: wire up app entry point and navigation"
```

---

## Task 10: Integration Test

**Step 1: Build release configuration**

Run: Product → Build (Release)
Expected: Build Succeeded

**Step 2: Manual test checklist**

- [ ] Launch app - shows Import view
- [ ] Tap "Import Worksheet" - opens file picker
- [ ] Select MOG .xlsx file - parses and shows Counting view
- [ ] Items grouped by location
- [ ] Search filters list
- [ ] Swipe right - count increments
- [ ] Swipe left - count decrements
- [ ] Tap count - numpad appears
- [ ] Toggle "Uncounted" - hides counted items
- [ ] Tap Export - shows summary
- [ ] Export - share sheet appears

**Step 3: Final commit**

```bash
git add -A
git commit -m "feat: Spectre Counter MVP complete"
```

---

## Summary

| Task | Description |
|------|-------------|
| 1 | Project setup with CoreXLSX |
| 2 | Data models (InventoryItem, CountSession) |
| 3 | XLSX parser service |
| 4 | CSV writer service |
| 5 | Import view with file picker |
| 6 | Item row with swipe gestures |
| 7 | Counting view with grouped list |
| 8 | Export view with share sheet |
| 9 | App entry point |
| 10 | Integration testing |

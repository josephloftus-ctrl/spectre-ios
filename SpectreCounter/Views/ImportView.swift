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

            let parseResult = try XLSXParser.parse(url: localURL)

            for session in sessions {
                modelContext.delete(session)
            }

            let session = CountSession(
                sourceFilename: url.lastPathComponent,
                quantityColumn: parseResult.quantityColumn,
                templatePath: localURL.path
            )
            session.items = parseResult.items
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

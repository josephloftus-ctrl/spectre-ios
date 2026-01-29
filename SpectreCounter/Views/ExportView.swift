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
            let url = try XLSXWriter.export(session: session)
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

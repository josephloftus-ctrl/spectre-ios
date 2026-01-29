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

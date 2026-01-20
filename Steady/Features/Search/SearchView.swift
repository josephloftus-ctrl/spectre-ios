import SwiftUI

struct SearchView: View {
    @EnvironmentObject var api: SteadyAPI
    @State private var searchText = ""
    @State private var selectedCollection: String? = nil
    @State private var results: [SearchResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    let collections = ["knowledge_base", "food_knowledge", "living_memory"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    collectionPicker

                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if results.isEmpty && !searchText.isEmpty {
                        emptyResultsView
                    } else if results.isEmpty {
                        emptyStateView
                    } else {
                        resultsList
                    }
                }
            }
            .navigationTitle("Search")
            .toolbarBackground(SteadyTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .searchable(text: $searchText, prompt: "Search knowledge base")
            .onSubmit(of: .search) {
                Task {
                    await performSearch()
                }
            }
        }
    }

    private var collectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SteadyTheme.Spacing.sm) {
                collectionChip(title: "All", collection: nil)
                ForEach(collections, id: \.self) { collection in
                    collectionChip(title: formatCollectionName(collection), collection: collection)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, SteadyTheme.Spacing.sm)
        }
        .background(SteadyTheme.cardBackground)
    }

    private func collectionChip(title: String, collection: String?) -> some View {
        Button {
            selectedCollection = collection
            if !searchText.isEmpty {
                Task {
                    await performSearch()
                }
            }
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(selectedCollection == collection ? .semibold : .regular)
                .foregroundColor(selectedCollection == collection ? .white : .steadyTextSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedCollection == collection ? SteadyTheme.primary : SteadyTheme.secondaryBackground)
                .cornerRadius(SteadyTheme.Radius.full)
        }
    }

    private func formatCollectionName(_ name: String) -> String {
        name.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: SteadyTheme.Spacing.sm) {
                ForEach(results) { result in
                    SearchResultCard(result: result)
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: SteadyTheme.Spacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.steadyTextSecondary)

            Text("Search your knowledge base")
                .font(.headline)
                .foregroundColor(.steadyText)

            Text("Find documents, SOPs, and training materials")
                .font(.subheadline)
                .foregroundColor(.steadyTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private var emptyResultsView: some View {
        VStack(spacing: SteadyTheme.Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.steadyTextSecondary)

            Text("No results found")
                .font(.headline)
                .foregroundColor(.steadyText)

            Text("Try a different search term or collection")
                .font(.subheadline)
                .foregroundColor(.steadyTextSecondary)
        }
        .padding()
    }

    private func performSearch() async {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let response = try await api.search(query: trimmed, collection: selectedCollection)
            results = response.results
        } catch {
            errorMessage = error.localizedDescription
            results = []
        }

        isLoading = false
    }
}

struct SearchResultCard: View {
    let result: SearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            if let source = result.source {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.steadyPrimary)
                    Text(source)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.steadyPrimary)
                    Spacer()

                    if let score = result.score {
                        Text("\(Int(score * 100))% match")
                            .font(.caption)
                            .foregroundColor(.steadyTextTertiary)
                    }
                }
            }

            Text(result.content)
                .font(.body)
                .foregroundColor(.steadyText)
                .lineLimit(6)

            if let metadata = result.metadata {
                HStack {
                    if let collection = metadata.collection {
                        Text(collection.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(SteadyTheme.secondaryBackground)
                            .cornerRadius(SteadyTheme.Radius.sm)
                            .foregroundColor(.steadyTextSecondary)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: SteadyTheme.Radius.lg)
                .stroke(SteadyTheme.borderSubtle, lineWidth: 1)
        )
    }
}

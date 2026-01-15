import SwiftUI
import SwiftData

struct NotesView: View {
    @EnvironmentObject var api: SteadyAPI
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.createdAt, order: .reverse) private var notes: [Note]
    @State private var showingNewNote = false
    @State private var searchText = ""

    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notes
        }
        return notes.filter { note in
            note.content.localizedCaseInsensitiveContains(searchText) ||
            note.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                if notes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
            .navigationTitle("Notes")
            .toolbarBackground(SteadyTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewNote = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.steadyPrimary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search notes")
            .sheet(isPresented: $showingNewNote) {
                NoteEditorView(onSave: { content, tags in
                    addNote(content: content, tags: tags)
                })
            }
        }
    }

    private var notesList: some View {
        ScrollView {
            LazyVStack(spacing: SteadyTheme.Spacing.sm) {
                ForEach(filteredNotes) { note in
                    NoteCardView(note: note)
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteNote(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: SteadyTheme.Spacing.md) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundColor(.steadyTextSecondary)

            Text("No notes yet")
                .font(.headline)
                .foregroundColor(.steadyText)

            Text("Tap + to create your first note")
                .font(.subheadline)
                .foregroundColor(.steadyTextSecondary)

            Button {
                showingNewNote = true
            } label: {
                Label("New Note", systemImage: "plus")
            }
            .steadyPrimaryButton()
            .padding(.top, SteadyTheme.Spacing.md)
        }
    }

    private func addNote(content: String, tags: [String]) {
        let note = Note(content: content, tags: tags)
        modelContext.insert(note)
    }

    private func deleteNote(_ note: Note) {
        modelContext.delete(note)
    }
}

struct NoteCardView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
            Text(note.content)
                .font(.body)
                .foregroundColor(.steadyText)
                .lineLimit(4)

            HStack {
                if !note.tags.isEmpty {
                    ForEach(note.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(SteadyTheme.secondaryBackground)
                            .cornerRadius(SteadyTheme.Radius.sm)
                            .foregroundColor(.steadyTextSecondary)
                    }
                }

                Spacer()

                Text(note.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.steadyTextTertiary)
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

struct NoteEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var content = ""
    @State private var tagInput = ""
    @State private var tags: [String] = []

    let onSave: (String, [String]) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                VStack(spacing: SteadyTheme.Spacing.md) {
                    TextEditor(text: $content)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(SteadyTheme.cardBackground)
                        .cornerRadius(SteadyTheme.Radius.md)
                        .frame(minHeight: 200)

                    VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
                        Text("Tags")
                            .font(.caption)
                            .foregroundColor(.steadyTextSecondary)

                        HStack {
                            TextField("Add tag", text: $tagInput)
                                .textFieldStyle(.plain)
                                .padding(SteadyTheme.Spacing.sm)
                                .background(SteadyTheme.cardBackground)
                                .cornerRadius(SteadyTheme.Radius.sm)
                                .onSubmit {
                                    addTag()
                                }

                            Button {
                                addTag()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.steadyPrimary)
                            }
                        }

                        if !tags.isEmpty {
                            FlowLayout(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    HStack(spacing: 4) {
                                        Text(tag)
                                        Button {
                                            tags.removeAll { $0 == tag }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(SteadyTheme.primary.opacity(0.2))
                                    .cornerRadius(SteadyTheme.Radius.sm)
                                    .foregroundColor(.steadyPrimary)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(content, tags)
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            tagInput = ""
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > width && x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                maxHeight = max(maxHeight, size.height)
                x += size.width + spacing
            }

            size = CGSize(width: width, height: y + maxHeight)
        }
    }
}

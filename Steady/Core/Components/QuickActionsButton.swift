import SwiftUI

struct QuickActionsButton: View {
    @Binding var isExpanded: Bool
    @State private var showingQuickNote = false
    @State private var showingNewCount = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isExpanded {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded = false
                        }
                    }
            }

            VStack(alignment: .trailing, spacing: SteadyTheme.Spacing.sm) {
                if isExpanded {
                    quickActionItem(
                        icon: "note.text.badge.plus",
                        label: "Quick Note",
                        color: .steadyInfo
                    ) {
                        showingQuickNote = true
                        isExpanded = false
                    }
                    .transition(.scale.combined(with: .opacity))

                    quickActionItem(
                        icon: "list.clipboard",
                        label: "Start Count",
                        color: .steadySuccess
                    ) {
                        showingNewCount = true
                        isExpanded = false
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "xmark" : "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(SteadyTheme.primary)
                        .clipShape(Circle())
                        .shadow(color: SteadyTheme.cardShadow, radius: 8, y: 4)
                        .rotationEffect(.degrees(isExpanded ? 45 : 0))
                }
            }
        }
        .sheet(isPresented: $showingQuickNote) {
            QuickNoteSheet()
        }
        .sheet(isPresented: $showingNewCount) {
            NewCountSessionView()
        }
    }

    private func quickActionItem(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: SteadyTheme.Spacing.sm) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.steadyText)

                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
            }
            .padding(.leading, SteadyTheme.Spacing.md)
            .padding(.trailing, 6)
            .padding(.vertical, 6)
            .background(SteadyTheme.cardBackground)
            .cornerRadius(SteadyTheme.Radius.full)
            .shadow(color: SteadyTheme.cardShadow, radius: 4, y: 2)
        }
    }
}

struct QuickNoteSheet: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var content = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                VStack {
                    TextEditor(text: $content)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .background(SteadyTheme.cardBackground)
                        .cornerRadius(SteadyTheme.Radius.md)
                        .padding()

                    Spacer()
                }
            }
            .navigationTitle("Quick Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveNote()
                        dismiss()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveNote() {
        let note = Note(content: content)
        modelContext.insert(note)
    }
}

#Preview {
    ZStack {
        Color.steadyBackground.ignoresSafeArea()
        VStack {
            Spacer()
            HStack {
                Spacer()
                QuickActionsButton(isExpanded: .constant(true))
                    .padding()
            }
        }
    }
    .preferredColorScheme(.dark)
}

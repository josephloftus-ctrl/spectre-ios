import SwiftUI

struct ChatView: View {
    @EnvironmentObject var api: SteadyAPI
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    messagesList
                    inputBar
                }
            }
            .navigationTitle("Assistant")
            .toolbarBackground(SteadyTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.clearConversation()
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.steadyTextSecondary)
                    }
                }
            }
            .onAppear {
                viewModel.api = api
            }
        }
    }

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: SteadyTheme.Spacing.md) {
                    if viewModel.messages.isEmpty {
                        welcomeView
                    } else {
                        ForEach(viewModel.messages) { message in
                            ChatMessageView(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            typingIndicator
                        }
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var welcomeView: some View {
        VStack(spacing: SteadyTheme.Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.steadyPrimary)

            Text("Steady Assistant")
                .font(.title2.weight(.bold))
                .foregroundColor(.steadyText)

            Text("Ask me anything about your inventory, operations, or documentation.")
                .font(.subheadline)
                .foregroundColor(.steadyTextSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: SteadyTheme.Spacing.sm) {
                suggestionButton("What are today's critical issues?")
                suggestionButton("Show me inventory trends")
                suggestionButton("How do I count frozen items?")
            }
            .padding(.top, SteadyTheme.Spacing.md)
        }
        .padding(.vertical, SteadyTheme.Spacing.xxl)
    }

    private func suggestionButton(_ text: String) -> some View {
        Button {
            viewModel.inputText = text
            Task {
                await viewModel.sendMessage()
            }
        } label: {
            Text(text)
                .font(.subheadline)
                .foregroundColor(.steadyPrimary)
                .padding(.horizontal, SteadyTheme.Spacing.md)
                .padding(.vertical, SteadyTheme.Spacing.sm)
                .background(SteadyTheme.primary.opacity(0.1))
                .cornerRadius(SteadyTheme.Radius.full)
        }
    }

    private var typingIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.steadyTextTertiary)
                    .frame(width: 8, height: 8)
                    .opacity(0.5)
            }
        }
        .padding()
        .background(SteadyTheme.cardBackground)
        .cornerRadius(SteadyTheme.Radius.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(SteadyTheme.border)

            HStack(spacing: SteadyTheme.Spacing.sm) {
                TextField("Ask anything...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isInputFocused)
                    .onSubmit {
                        Task { await viewModel.sendMessage() }
                    }

                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    Image(systemName: viewModel.isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.inputText.isEmpty ? .steadyTextTertiary : .steadyPrimary)
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty && !viewModel.isLoading)
            }
            .padding()
            .background(SteadyTheme.cardBackground)
        }
    }
}

struct ChatMessageView: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: SteadyTheme.Spacing.sm) {
            if message.role == .assistant {
                assistantAvatar
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : .steadyText)
                    .padding()
                    .background(message.role == .user ? SteadyTheme.primary : SteadyTheme.cardBackground)
                    .cornerRadius(SteadyTheme.Radius.lg)

                if let sources = message.sources, !sources.isEmpty {
                    sourcesView(sources)
                }

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.steadyTextTertiary)
            }
            .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)

            if message.role == .user {
                userAvatar
            }
        }
    }

    private var assistantAvatar: some View {
        Image(systemName: "sparkles")
            .font(.caption)
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(SteadyTheme.primary)
            .clipShape(Circle())
    }

    private var userAvatar: some View {
        Image(systemName: "person.fill")
            .font(.caption)
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(SteadyTheme.secondaryBackground)
            .clipShape(Circle())
    }

    private func sourcesView(_ sources: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sources")
                .font(.caption2.weight(.medium))
                .foregroundColor(.steadyTextSecondary)

            ForEach(sources, id: \.self) { source in
                HStack(spacing: 4) {
                    Image(systemName: "doc.text")
                        .font(.caption2)
                    Text(source)
                        .font(.caption2)
                }
                .foregroundColor(.steadyPrimary)
            }
        }
        .padding(SteadyTheme.Spacing.sm)
        .background(SteadyTheme.secondaryBackground)
        .cornerRadius(SteadyTheme.Radius.sm)
    }
}

// MARK: - ViewModel

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isLoading = false

    var api: SteadyAPI?

    func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        inputText = ""

        isLoading = true

        do {
            let response = try await api?.chat(message: trimmed, history: messages.dropLast().map { $0.toChatHistoryItem() })
            let assistantMessage = ChatMessage(
                role: .assistant,
                content: response?.answer ?? "I couldn't generate a response.",
                sources: response?.sources
            )
            messages.append(assistantMessage)
        } catch {
            let errorMessage = ChatMessage(
                role: .assistant,
                content: "Sorry, I encountered an error: \(error.localizedDescription)"
            )
            messages.append(errorMessage)
        }

        isLoading = false
    }

    func clearConversation() {
        messages = []
    }
}

// MARK: - Models

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: ChatRole
    let content: String
    let sources: [String]?
    let timestamp = Date()

    init(role: ChatRole, content: String, sources: [String]? = nil) {
        self.role = role
        self.content = content
        self.sources = sources
    }

    func toChatHistoryItem() -> ChatHistoryItem {
        ChatHistoryItem(role: role.rawValue, content: content)
    }
}

enum ChatRole: String {
    case user
    case assistant
}

struct ChatHistoryItem: Codable {
    let role: String
    let content: String
}

struct ChatResponse: Codable {
    let answer: String
    let sources: [String]?
    let confidence: String?
}

import SwiftUI

struct HelpdeskBarView: View {
    @ObservedObject var viewModel: HelpdeskViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(SteadyTheme.border)

            HStack(spacing: 12) {
                TextField("Ask a question...", text: $viewModel.question)
                    .textFieldStyle(.plain)
                    .padding(SteadyTheme.Spacing.sm)
                    .background(SteadyTheme.secondaryBackground)
                    .cornerRadius(SteadyTheme.Radius.md)
                    .disabled(viewModel.isLoading)
                    .onSubmit {
                        Task {
                            await viewModel.askQuestion()
                        }
                    }

                Button {
                    Task {
                        await viewModel.askQuestion()
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                            .foregroundColor(.steadyPrimary)
                    }
                }
                .disabled(viewModel.question.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(SteadyTheme.cardBackground)
        }
        .sheet(isPresented: $viewModel.showingResponse) {
            HelpdeskResponseSheet(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

struct HelpdeskResponseSheet: View {
    @ObservedObject var viewModel: HelpdeskViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: SteadyTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your Question")
                                .font(.caption)
                                .foregroundColor(.steadyTextSecondary)
                            Text(viewModel.question)
                                .font(.body)
                                .foregroundColor(.steadyText)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SteadyTheme.cardBackground)
                        .cornerRadius(SteadyTheme.Radius.md)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Answer")
                                .font(.caption)
                                .foregroundColor(.steadyTextSecondary)
                            Text(viewModel.response?.answer ?? "No answer")
                                .font(.body)
                                .foregroundColor(.steadyText)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(SteadyTheme.cardBackground)
                        .cornerRadius(SteadyTheme.Radius.md)

                        if let confidence = viewModel.response?.confidence {
                            HStack {
                                Text("Confidence:")
                                    .font(.caption)
                                    .foregroundColor(.steadyTextSecondary)
                                confidenceBadge(confidence)
                            }
                        }

                        if let sources = viewModel.response?.sources, !sources.isEmpty {
                            VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
                                Text("Sources")
                                    .font(.caption)
                                    .foregroundColor(.steadyTextSecondary)

                                ForEach(sources, id: \.self) { source in
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.text")
                                            .font(.caption)
                                            .foregroundColor(.steadyPrimary)
                                        Text(source)
                                            .font(.caption)
                                            .foregroundColor(.steadyText)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(SteadyTheme.cardBackground)
                            .cornerRadius(SteadyTheme.Radius.md)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Helpdesk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(SteadyTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        viewModel.clearResponse()
                    }
                }
            }
        }
    }

    private func confidenceBadge(_ confidence: String) -> some View {
        let (color, text) = confidenceColor(confidence)
        return Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(SteadyTheme.Radius.sm)
    }

    private func confidenceColor(_ confidence: String) -> (Color, String) {
        switch confidence.lowercased() {
        case "high":
            return (.steadySuccess, "High")
        case "medium":
            return (.steadyWarning, "Medium")
        default:
            return (.steadyDestructive, "Low")
        }
    }
}

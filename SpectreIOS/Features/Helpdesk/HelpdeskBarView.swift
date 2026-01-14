import SwiftUI

struct HelpdeskBarView: View {
    @ObservedObject var viewModel: HelpdeskViewModel

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                TextField("Ask a question...", text: $viewModel.question)
                    .textFieldStyle(.roundedBorder)
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
                    }
                }
                .disabled(viewModel.question.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Question")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.question)
                            .font(.body)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Answer")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(viewModel.response?.answer ?? "No answer")
                            .font(.body)
                    }

                    if let confidence = viewModel.response?.confidence {
                        HStack {
                            Text("Confidence:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            confidenceBadge(confidence)
                        }
                    }

                    if let sources = viewModel.response?.sources, !sources.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sources")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            ForEach(sources, id: \.self) { source in
                                HStack(spacing: 4) {
                                    Image(systemName: "doc.text")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(source)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Helpdesk")
            .navigationBarTitleDisplayMode(.inline)
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
            .cornerRadius(4)
    }

    private func confidenceColor(_ confidence: String) -> (Color, String) {
        switch confidence.lowercased() {
        case "high":
            return (.green, "High")
        case "medium":
            return (.orange, "Medium")
        default:
            return (.red, "Low")
        }
    }
}

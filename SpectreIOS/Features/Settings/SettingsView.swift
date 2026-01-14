import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var api: SpectreAPI
    @State private var backendURL: String = ""
    @State private var showingSaveConfirmation = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Backend URL")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("http://localhost:8000", text: $backendURL)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Server Configuration")
                } footer: {
                    Text("Enter the full URL of your Spectre backend server")
                }

                Section {
                    Button("Save Configuration") {
                        saveConfiguration()
                    }
                    .disabled(backendURL.isEmpty)
                }

                Section {
                    Button("Reset to Default") {
                        backendURL = AppSettings.defaultBackendURL
                    }
                    .foregroundColor(.secondary)
                }

                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        if api.isConfigured {
                            Label("Configured", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Label("Not Configured", systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Connection")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                backendURL = AppSettings.shared.backendURL ?? AppSettings.defaultBackendURL
            }
            .alert("Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Backend URL has been updated")
            }
        }
    }

    private func saveConfiguration() {
        api.updateBaseURL(backendURL)
        showingSaveConfirmation = true
    }
}

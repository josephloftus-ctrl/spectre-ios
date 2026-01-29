import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var api: SteadyAPI
    @State private var backendURL: String = ""
    @State private var showingSaveConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.steadyBackground.ignoresSafeArea()

                Form {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Backend URL")
                                .font(.caption)
                                .foregroundColor(.steadyTextSecondary)

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
                        Text("Enter the full URL of your Steady backend server")
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
                        .foregroundColor(.steadyTextSecondary)
                    }

                    Section {
                        HStack {
                            Text("Status")
                            Spacer()
                            if api.isConfigured {
                                Label("Configured", systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.steadySuccess)
                                    .font(.caption)
                            } else {
                                Label("Not Configured", systemImage: "xmark.circle.fill")
                                    .foregroundColor(.steadyDestructive)
                                    .font(.caption)
                            }
                        }
                    } header: {
                        Text("Connection")
                    }

                    Section {
                        VStack(alignment: .leading, spacing: SteadyTheme.Spacing.sm) {
                            Text("Steady")
                                .font(.headline)
                                .foregroundColor(.steadyText)
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.steadyTextSecondary)
                        }
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(SteadyTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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

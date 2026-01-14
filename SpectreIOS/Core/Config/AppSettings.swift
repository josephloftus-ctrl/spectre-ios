import Foundation

class AppSettings {
    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let backendURL = "spectre_backend_url"
    }

    var backendURL: String? {
        get { defaults.string(forKey: Keys.backendURL) }
        set { defaults.set(newValue, forKey: Keys.backendURL) }
    }

    static let defaultBackendURL = "http://localhost:8000"
}

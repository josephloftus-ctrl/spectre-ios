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

    static let defaultBackendURL = "https://api.josephloftus.com"

    // Cloudflare Access credentials
    static let cfAccessClientId = "ab7daeaba96c1b5c003abc43a2e51e21.access"
    static let cfAccessClientSecret = "c2318a24672f9dcbb3063ee3287a46326f789178b57978f5e6e19a16661335e4"
}

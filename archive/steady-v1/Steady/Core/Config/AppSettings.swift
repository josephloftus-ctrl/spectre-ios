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
    static var cfAccessClientId: String {
        Bundle.main.object(forInfoDictionaryKey: "CFAccessClientId") as? String ?? ""
    }
    
    static var cfAccessClientSecret: String {
        Bundle.main.object(forInfoDictionaryKey: "CFAccessClientSecret") as? String ?? ""
    }
}

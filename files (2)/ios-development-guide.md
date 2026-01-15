# iOS Development Best Practices

A comprehensive guide to professional iOS development with modern patterns, architecture, and practices.

---

## 1. Project Architecture

### MVVM (Model-View-ViewModel)

The standard architecture for SwiftUI apps. Clean separation of concerns.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│    View     │────▶│  ViewModel  │────▶│    Model    │
│  (SwiftUI)  │◀────│ (Observable)│◀────│   (Data)    │
└─────────────┘     └─────────────┘     └─────────────┘
```

**Structure:**

```swift
// Model - Pure data
struct User: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String
}

// ViewModel - Business logic & state
@Observable
class UserViewModel {
    private let repository: UserRepository
    
    var user: User?
    var isLoading = false
    var error: Error?
    
    init(repository: UserRepository = .live) {
        self.repository = repository
    }
    
    func load() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            user = try await repository.fetchCurrentUser()
        } catch {
            self.error = error
        }
    }
    
    func updateName(_ name: String) async {
        guard var user else { return }
        user.name = name
        
        do {
            self.user = try await repository.save(user)
        } catch {
            self.error = error
        }
    }
}

// View - UI only
struct UserProfileView: View {
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let user = viewModel.user {
                ProfileContent(user: user)
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
```

### The Composable Architecture (TCA)

For complex apps needing predictable state management. More boilerplate, but excellent testability.

```swift
import ComposableArchitecture

@Reducer
struct UserFeature {
    @ObservableState
    struct State: Equatable {
        var user: User?
        var isLoading = false
    }
    
    enum Action {
        case onAppear
        case userLoaded(User)
        case loadFailed(Error)
    }
    
    @Dependency(\.userClient) var userClient
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let user = try await userClient.fetch()
                    await send(.userLoaded(user))
                } catch: { error, send in
                    await send(.loadFailed(error))
                }
                
            case .userLoaded(let user):
                state.isLoading = false
                state.user = user
                return .none
                
            case .loadFailed:
                state.isLoading = false
                return .none
            }
        }
    }
}
```

### Clean Architecture

For enterprise-scale apps. Multiple layers with clear boundaries.

```
┌────────────────────────────────────────────────┐
│                 Presentation                    │
│        (Views, ViewModels, Coordinators)        │
├────────────────────────────────────────────────┤
│                   Domain                        │
│      (Use Cases, Entities, Repositories)        │
├────────────────────────────────────────────────┤
│                    Data                         │
│    (Network, Database, Repository Impls)        │
└────────────────────────────────────────────────┘
```

### When to Use What

| App Size | Complexity | Architecture |
|----------|------------|--------------|
| Small | Simple | MVVM |
| Medium | Moderate | MVVM + Coordinator |
| Large | Complex | TCA or Clean Architecture |
| Enterprise | Very Complex | Clean Architecture |

---

## 2. Project Structure

### Recommended Folder Organization

```
MyApp/
├── App/
│   ├── MyApp.swift              # @main entry point
│   ├── AppDelegate.swift        # If needed for UIKit integration
│   └── SceneDelegate.swift      # If needed
├── Features/
│   ├── Authentication/
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   └── SignUpView.swift
│   │   ├── ViewModels/
│   │   │   └── AuthViewModel.swift
│   │   └── Models/
│   │       └── AuthState.swift
│   ├── Home/
│   │   ├── Views/
│   │   ├── ViewModels/
│   │   └── Models/
│   └── Profile/
│       ├── Views/
│       ├── ViewModels/
│       └── Models/
├── Core/
│   ├── Network/
│   │   ├── APIClient.swift
│   │   ├── Endpoints.swift
│   │   └── NetworkError.swift
│   ├── Persistence/
│   │   ├── CoreDataStack.swift
│   │   └── UserDefaults+Extensions.swift
│   ├── Services/
│   │   ├── AuthService.swift
│   │   └── AnalyticsService.swift
│   └── Utilities/
│       ├── Constants.swift
│       ├── Logger.swift
│       └── Extensions/
├── Shared/
│   ├── Components/
│   │   ├── Buttons/
│   │   ├── Cards/
│   │   └── Loading/
│   ├── Modifiers/
│   └── Styles/
├── Resources/
│   ├── Assets.xcassets
│   ├── Localizable.xcstrings
│   └── Info.plist
└── Tests/
    ├── UnitTests/
    ├── IntegrationTests/
    └── UITests/
```

### Feature-Based vs Layer-Based

**Feature-Based (Recommended for larger apps):**
- Group by feature/screen
- Each feature is self-contained
- Easier to find related code
- Better for teams

**Layer-Based (Simpler for small apps):**
- Group by type (Views, ViewModels, Models)
- Simpler mental model
- Can get messy as app grows

---

## 3. Dependency Injection

### Protocol-Based DI

```swift
// Define protocol
protocol UserRepositoryProtocol {
    func fetchUser(id: UUID) async throws -> User
    func saveUser(_ user: User) async throws -> User
    func deleteUser(id: UUID) async throws
}

// Production implementation
class UserRepository: UserRepositoryProtocol {
    private let apiClient: APIClient
    private let cache: UserCache
    
    init(apiClient: APIClient = .shared, cache: UserCache = .shared) {
        self.apiClient = apiClient
        self.cache = cache
    }
    
    func fetchUser(id: UUID) async throws -> User {
        if let cached = cache.get(id: id) {
            return cached
        }
        let user = try await apiClient.fetch(endpoint: .user(id))
        cache.set(user)
        return user
    }
    
    func saveUser(_ user: User) async throws -> User {
        try await apiClient.post(endpoint: .user(user.id), body: user)
    }
    
    func deleteUser(id: UUID) async throws {
        try await apiClient.delete(endpoint: .user(id))
    }
}

// Mock for testing
class MockUserRepository: UserRepositoryProtocol {
    var users: [UUID: User] = [:]
    var fetchError: Error?
    var saveError: Error?
    
    func fetchUser(id: UUID) async throws -> User {
        if let error = fetchError { throw error }
        guard let user = users[id] else { throw UserError.notFound }
        return user
    }
    
    func saveUser(_ user: User) async throws -> User {
        if let error = saveError { throw error }
        users[user.id] = user
        return user
    }
    
    func deleteUser(id: UUID) async throws {
        users.removeValue(forKey: id)
    }
}
```

### Environment-Based DI (SwiftUI)

```swift
// Define environment key
private struct UserRepositoryKey: EnvironmentKey {
    static let defaultValue: UserRepositoryProtocol = UserRepository()
}

extension EnvironmentValues {
    var userRepository: UserRepositoryProtocol {
        get { self[UserRepositoryKey.self] }
        set { self[UserRepositoryKey.self] = newValue }
    }
}

// Inject in app
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.userRepository, UserRepository())
        }
    }
}

// Use in views
struct ProfileView: View {
    @Environment(\.userRepository) var repository
    @State private var user: User?
    
    var body: some View {
        // View code
    }
}

// Mock in previews
#Preview {
    ProfileView()
        .environment(\.userRepository, MockUserRepository())
}
```

### Container Pattern

```swift
@Observable
class DependencyContainer {
    // Services
    let apiClient: APIClient
    let authService: AuthService
    let analyticsService: AnalyticsService
    
    // Repositories
    lazy var userRepository: UserRepositoryProtocol = UserRepository(apiClient: apiClient)
    lazy var itemRepository: ItemRepositoryProtocol = ItemRepository(apiClient: apiClient)
    
    init(
        apiClient: APIClient = .live,
        authService: AuthService = .live,
        analyticsService: AnalyticsService = .live
    ) {
        self.apiClient = apiClient
        self.authService = authService
        self.analyticsService = analyticsService
    }
    
    static let live = DependencyContainer()
    static let mock = DependencyContainer(
        apiClient: .mock,
        authService: .mock,
        analyticsService: .mock
    )
}

// Use in app
@main
struct MyApp: App {
    @State private var container = DependencyContainer.live
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(container)
        }
    }
}
```

---

## 4. Networking

### Modern API Client

```swift
// Endpoint Definition
enum Endpoint {
    case users
    case user(UUID)
    case createUser
    case items(page: Int, limit: Int)
    
    var path: String {
        switch self {
        case .users, .createUser: return "/users"
        case .user(let id): return "/users/\(id)"
        case .items: return "/items"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .users, .user, .items: return .get
        case .createUser: return .post
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .items(let page, let limit):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
        default:
            return nil
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// API Client
actor APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(
        baseURL: URL = URL(string: "https://api.example.com")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .convertToSnakeCase
    }
    
    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(endpoint: endpoint)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
    
    func send<Body: Encodable, Response: Decodable>(
        _ endpoint: Endpoint,
        body: Body
    ) async throws -> Response {
        var request = try buildRequest(endpoint: endpoint)
        request.httpBody = try encoder.encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try decoder.decode(Response.self, from: data)
    }
    
    private func buildRequest(endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)!
        components.queryItems = endpoint.queryItems
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add auth token if available
        if let token = TokenStore.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 404:
            throw NetworkError.notFound
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            throw NetworkError.unknown(httpResponse.statusCode)
        }
    }
}

// Error Types
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(Int)
    case unknown(Int)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "Please log in again"
        case .notFound: return "Resource not found"
        case .serverError(let code): return "Server error (\(code))"
        case .unknown(let code): return "Unknown error (\(code))"
        case .decodingError(let error): return "Data error: \(error.localizedDescription)"
        }
    }
}
```

### Request Retry & Exponential Backoff

```swift
extension APIClient {
    func fetchWithRetry<T: Decodable>(
        _ endpoint: Endpoint,
        maxRetries: Int = 3,
        initialDelay: Duration = .seconds(1)
    ) async throws -> T {
        var lastError: Error?
        var delay = initialDelay
        
        for attempt in 0..<maxRetries {
            do {
                return try await fetch(endpoint)
            } catch {
                lastError = error
                
                // Don't retry client errors (4xx)
                if case NetworkError.unauthorized = error { throw error }
                if case NetworkError.notFound = error { throw error }
                
                if attempt < maxRetries - 1 {
                    try await Task.sleep(for: delay)
                    delay *= 2  // Exponential backoff
                }
            }
        }
        
        throw lastError ?? NetworkError.unknown(0)
    }
}
```

### Response Caching

```swift
actor ResponseCache {
    private var cache: [String: CacheEntry] = [:]
    private let maxAge: TimeInterval
    
    struct CacheEntry {
        let data: Data
        let timestamp: Date
    }
    
    init(maxAge: TimeInterval = 300) {  // 5 minutes default
        self.maxAge = maxAge
    }
    
    func get(key: String) -> Data? {
        guard let entry = cache[key] else { return nil }
        guard Date().timeIntervalSince(entry.timestamp) < maxAge else {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }
    
    func set(key: String, data: Data) {
        cache[key] = CacheEntry(data: data, timestamp: Date())
    }
    
    func invalidate(key: String) {
        cache.removeValue(forKey: key)
    }
    
    func invalidateAll() {
        cache.removeAll()
    }
}
```

---

## 5. Data Persistence

### SwiftData (iOS 17+)

```swift
import SwiftData

// Model
@Model
class Item {
    var id: UUID
    var title: String
    var notes: String
    var createdAt: Date
    var isCompleted: Bool
    
    @Relationship(deleteRule: .cascade)
    var tags: [Tag]
    
    init(title: String, notes: String = "") {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.createdAt = Date()
        self.isCompleted = false
        self.tags = []
    }
}

@Model
class Tag {
    var name: String
    var color: String
    
    @Relationship(inverse: \Item.tags)
    var items: [Item]
    
    init(name: String, color: String = "blue") {
        self.name = name
        self.color = color
        self.items = []
    }
}

// Setup in App
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Item.self, Tag.self])
    }
}

// Usage in Views
struct ItemListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Item.createdAt, order: .reverse) private var items: [Item]
    
    var body: some View {
        List(items) { item in
            ItemRow(item: item)
                .swipeActions {
                    Button(role: .destructive) {
                        context.delete(item)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
        }
    }
    
    func addItem(title: String) {
        let item = Item(title: title)
        context.insert(item)
    }
}

// Filtered queries
struct CompletedItemsView: View {
    @Query(
        filter: #Predicate<Item> { $0.isCompleted },
        sort: \Item.createdAt
    ) private var completedItems: [Item]
    
    var body: some View {
        List(completedItems) { item in
            ItemRow(item: item)
        }
    }
}
```

### Core Data (iOS 10+)

```swift
// Core Data Stack
class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyApp")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            print("Failed to save: \(error)")
        }
    }
}
```

### UserDefaults (Simple Key-Value)

```swift
// Type-safe UserDefaults
@propertyWrapper
struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    let container: UserDefaults
    
    init(key: String, defaultValue: Value, container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
    }
    
    var wrappedValue: Value {
        get {
            container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            container.set(newValue, forKey: key)
        }
    }
}

// For Codable types
@propertyWrapper
struct CodableUserDefault<Value: Codable> {
    let key: String
    let defaultValue: Value
    let container: UserDefaults
    
    init(key: String, defaultValue: Value, container: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.container = container
    }
    
    var wrappedValue: Value {
        get {
            guard let data = container.data(forKey: key) else { return defaultValue }
            return (try? JSONDecoder().decode(Value.self, from: data)) ?? defaultValue
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            container.set(data, forKey: key)
        }
    }
}

// Usage
class AppSettings {
    static let shared = AppSettings()
    
    @UserDefault(key: "hasCompletedOnboarding", defaultValue: false)
    var hasCompletedOnboarding: Bool
    
    @UserDefault(key: "preferredTheme", defaultValue: "system")
    var preferredTheme: String
    
    @CodableUserDefault(key: "lastViewedItems", defaultValue: [])
    var lastViewedItems: [UUID]
}
```

### Keychain (Secure Storage)

```swift
import Security

enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case unexpectedStatus(OSStatus)
}

class KeychainManager {
    static let shared = KeychainManager()
    private let service = Bundle.main.bundleIdentifier ?? "com.app"
    
    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try update(data, for: key)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func load(key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            throw KeychainError.itemNotFound
        }
        
        return result as! Data
    }
    
    func update(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}

// Convenience for tokens
extension KeychainManager {
    func saveToken(_ token: String, for key: String = "accessToken") throws {
        guard let data = token.data(using: .utf8) else { return }
        try save(data, for: key)
    }
    
    func loadToken(key: String = "accessToken") -> String? {
        guard let data = try? load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

---

## 6. Error Handling

### Result Type Pattern

```swift
// Domain errors
enum AppError: LocalizedError {
    case network(NetworkError)
    case validation(ValidationError)
    case unauthorized
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .network(let error): return error.localizedDescription
        case .validation(let error): return error.localizedDescription
        case .unauthorized: return "Please log in to continue"
        case .unknown(let error): return error.localizedDescription
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .network: return "Check your internet connection and try again"
        case .validation: return "Please correct the highlighted fields"
        case .unauthorized: return "Tap to log in"
        case .unknown: return "Please try again later"
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyField(String)
    case invalidEmail
    case passwordTooShort
    case passwordMismatch
    
    var errorDescription: String? {
        switch self {
        case .emptyField(let field): return "\(field) is required"
        case .invalidEmail: return "Please enter a valid email address"
        case .passwordTooShort: return "Password must be at least 8 characters"
        case .passwordMismatch: return "Passwords do not match"
        }
    }
}
```

### ViewModel Error Handling

```swift
@Observable
class FormViewModel {
    var email = ""
    var password = ""
    var confirmPassword = ""
    
    var isLoading = false
    var error: AppError?
    var fieldErrors: [String: String] = [:]
    
    var isValid: Bool {
        fieldErrors.isEmpty && !email.isEmpty && !password.isEmpty
    }
    
    func validate() -> Bool {
        fieldErrors.removeAll()
        
        if email.isEmpty {
            fieldErrors["email"] = "Email is required"
        } else if !email.contains("@") {
            fieldErrors["email"] = "Invalid email format"
        }
        
        if password.isEmpty {
            fieldErrors["password"] = "Password is required"
        } else if password.count < 8 {
            fieldErrors["password"] = "Password must be at least 8 characters"
        }
        
        if confirmPassword != password {
            fieldErrors["confirmPassword"] = "Passwords do not match"
        }
        
        return fieldErrors.isEmpty
    }
    
    func submit() async {
        guard validate() else { return }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            try await authService.signUp(email: email, password: password)
        } catch let networkError as NetworkError {
            error = .network(networkError)
        } catch {
            error = .unknown(error)
        }
    }
    
    let authService = AuthService()
}
```

### Error Presentation

```swift
struct ErrorBanner: View {
    let error: AppError
    let dismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.localizedDescription)
                    .font(.subheadline.weight(.medium))
                
                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.caption)
                        .opacity(0.9)
                }
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
            }
        }
        .foregroundStyle(.white)
        .padding()
        .background(.red.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

// Usage with animation
struct ContentView: View {
    @State private var viewModel = FormViewModel()
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content
            Form { /* ... */ }
            
            // Error banner
            if let error = viewModel.error {
                ErrorBanner(error: error) {
                    withAnimation {
                        viewModel.error = nil
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring, value: viewModel.error != nil)
    }
}
```

---

## 7. Testing

### Unit Testing ViewModels

```swift
import XCTest
@testable import MyApp

final class UserViewModelTests: XCTestCase {
    var sut: UserViewModel!
    var mockRepository: MockUserRepository!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockUserRepository()
        sut = UserViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testLoadUser_Success() async {
        // Given
        let expectedUser = User(id: UUID(), name: "Test", email: "test@example.com")
        mockRepository.users[expectedUser.id] = expectedUser
        
        // When
        await sut.load(userId: expectedUser.id)
        
        // Then
        XCTAssertEqual(sut.user?.id, expectedUser.id)
        XCTAssertEqual(sut.user?.name, "Test")
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testLoadUser_NotFound() async {
        // Given
        mockRepository.fetchError = UserError.notFound
        
        // When
        await sut.load(userId: UUID())
        
        // Then
        XCTAssertNil(sut.user)
        XCTAssertNotNil(sut.error)
    }
    
    func testUpdateName_Success() async {
        // Given
        let user = User(id: UUID(), name: "Old", email: "test@example.com")
        mockRepository.users[user.id] = user
        sut.user = user
        
        // When
        await sut.updateName("New")
        
        // Then
        XCTAssertEqual(sut.user?.name, "New")
        XCTAssertEqual(mockRepository.users[user.id]?.name, "New")
    }
}
```

### Testing Async Code

```swift
final class APIClientTests: XCTestCase {
    var sut: APIClient!
    var mockSession: URLSession!
    
    override func setUp() {
        super.setUp()
        
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: config)
        
        sut = APIClient(session: mockSession)
    }
    
    func testFetchUsers_Success() async throws {
        // Given
        let expectedUsers = [User(id: UUID(), name: "Test", email: "test@example.com")]
        let data = try JSONEncoder().encode(expectedUsers)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
        
        // When
        let users: [User] = try await sut.fetch(.users)
        
        // Then
        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.name, "Test")
    }
    
    func testFetchUsers_Unauthorized() async {
        // Given
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        // When/Then
        do {
            let _: [User] = try await sut.fetch(.users)
            XCTFail("Expected unauthorized error")
        } catch NetworkError.unauthorized {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// Mock URL Protocol
class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler not set")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}
```

### UI Testing

```swift
import XCTest

final class LoginUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testSuccessfulLogin() {
        // Navigate to login if needed
        let loginButton = app.buttons["Log In"]
        if loginButton.exists {
            loginButton.tap()
        }
        
        // Enter credentials
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        // Submit
        app.buttons["Submit"].tap()
        
        // Verify navigation to home
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5))
    }
    
    func testLoginValidationErrors() {
        let submitButton = app.buttons["Submit"]
        submitButton.tap()
        
        // Check for validation errors
        XCTAssertTrue(app.staticTexts["Email is required"].exists)
        XCTAssertTrue(app.staticTexts["Password is required"].exists)
    }
}
```

### Snapshot Testing

```swift
import XCTest
import SnapshotTesting
@testable import MyApp

final class ComponentSnapshotTests: XCTestCase {
    func testProfileCard() {
        let view = ProfileCard(user: .preview)
            .frame(width: 375)
        
        assertSnapshot(of: view, as: .image)
    }
    
    func testProfileCard_DarkMode() {
        let view = ProfileCard(user: .preview)
            .frame(width: 375)
            .preferredColorScheme(.dark)
        
        assertSnapshot(of: view, as: .image)
    }
    
    func testProfileCard_LargeText() {
        let view = ProfileCard(user: .preview)
            .frame(width: 375)
            .dynamicTypeSize(.xxxLarge)
        
        assertSnapshot(of: view, as: .image)
    }
}
```

---

## 8. Accessibility

### VoiceOver Support

```swift
struct ItemCard: View {
    let item: Item
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(item.title)
                .font(.headline)
            
            Text(item.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack {
                Label("\(item.likes)", systemImage: "heart.fill")
                Label("\(item.comments)", systemImage: "bubble.right.fill")
            }
            .font(.caption)
        }
        // Combine into single accessible element
        .accessibilityElement(children: .combine)
        // Custom label
        .accessibilityLabel("\(item.title). \(item.description)")
        // Custom value
        .accessibilityValue("\(item.likes) likes, \(item.comments) comments")
        // Add hint for interaction
        .accessibilityHint("Double tap to view details")
        // Add custom actions
        .accessibilityAction(named: "Like") {
            // Like action
        }
        .accessibilityAction(named: "Comment") {
            // Comment action
        }
    }
}
```

### Dynamic Type Support

```swift
struct AdaptiveText: View {
    @Environment(\.dynamicTypeSize) var typeSize
    
    var body: some View {
        if typeSize >= .accessibility1 {
            // Vertical layout for very large text
            VStack(alignment: .leading) {
                Text("Title")
                    .font(.headline)
                Text("Subtitle")
                    .font(.subheadline)
            }
        } else {
            // Horizontal layout for normal text
            HStack {
                Text("Title")
                    .font(.headline)
                Spacer()
                Text("Subtitle")
                    .font(.subheadline)
            }
        }
    }
}

// Using scaled metrics
struct ScaledPadding: View {
    @ScaledMetric(relativeTo: .body) private var padding = 16
    
    var body: some View {
        Text("Content")
            .padding(padding)  // Scales with Dynamic Type
    }
}
```

### Color Contrast

```swift
// Use semantic colors
Text("Primary content")
    .foregroundStyle(.primary)      // Adapts to light/dark mode

Text("Secondary content")
    .foregroundStyle(.secondary)

// Check for reduced motion
struct AnimatedView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        Circle()
            .animation(reduceMotion ? nil : .spring, value: isAnimating)
    }
    
    @State private var isAnimating = false
}

// Check for increased contrast
struct ContrastAwareView: View {
    @Environment(\.colorSchemeContrast) var contrast
    
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(contrast == .increased ? .primary : .secondary, lineWidth: 1)
    }
}
```

---

## 9. Localization

### String Catalogs (iOS 17+)

Using `Localizable.xcstrings` (String Catalog):

```swift
// Automatic localization
Text("Welcome")  // Key: "Welcome"

// With comments for translators
Text("Submit", comment: "Button to submit the form")

// String interpolation
Text("Hello, \(userName)")  // Key: "Hello, %@"

// Pluralization (handled in String Catalog)
Text("item_count", comment: "Number of items")
// Configure in String Catalog:
// - one: "1 item"
// - other: "%lld items"
```

### Programmatic Localization

```swift
// NSLocalizedString (legacy)
let title = NSLocalizedString("welcome_title", comment: "Welcome screen title")

// String(localized:) (modern)
let greeting = String(localized: "greeting", defaultValue: "Hello!")

// With table
let errorMessage = String(localized: "network_error", table: "Errors")

// Formatted
let count = 5
let message = String(localized: "You have \(count) new messages")
```

### Locale-Aware Formatting

```swift
// Numbers
Text(price, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
Text(percentage, format: .percent)
Text(number, format: .number.precision(.fractionLength(2)))

// Dates
Text(date, format: .dateTime)
Text(date, format: .dateTime.day().month().year())
Text(date, format: Date.FormatStyle.relative(presentation: .numeric))

// Names
let name = PersonNameComponents(givenName: "John", familyName: "Doe")
Text(name, format: .name(style: .long))  // Respects locale order

// Lists
let items = ["Apple", "Banana", "Orange"]
Text(items, format: .list(type: .and))  // "Apple, Banana, and Orange"

// Measurements
let distance = Measurement(value: 5, unit: UnitLength.kilometers)
Text(distance, format: .measurement(width: .abbreviated))
```

### Right-to-Left Support

```swift
struct RTLAwareView: View {
    @Environment(\.layoutDirection) var layoutDirection
    
    var body: some View {
        HStack {
            Image(systemName: "chevron.left")
                .flipsForRightToLeftLayoutDirection(true)
            
            Text("Back")
        }
    }
}

// Force layout direction for testing
ContentView()
    .environment(\.layoutDirection, .rightToLeft)
```

---

## 10. Performance

### Instruments Profiling

Key instruments to use:

1. **Time Profiler** — CPU usage, find slow code
2. **Allocations** — Memory usage, find leaks
3. **SwiftUI** — View body evaluations, slow renders
4. **Network** — Request timing, payload sizes
5. **Core Animation** — Frame rate, offscreen rendering

### Optimizing SwiftUI

```swift
// ❌ Bad: Expensive computed property in body
struct BadView: View {
    let items: [Item]
    
    var body: some View {
        List(items.sorted(by: { $0.date > $1.date })) { item in  // Sorts every render!
            ItemRow(item: item)
        }
    }
}

// ✅ Good: Pre-compute or cache
struct GoodView: View {
    let items: [Item]
    
    private var sortedItems: [Item] {
        items.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        List(sortedItems) { item in
            ItemRow(item: item)
        }
    }
}

// Even better: Sort at data layer or use @Query sorting
```

### Image Optimization

```swift
// Async image loading with caching
struct CachedAsyncImage: View {
    let url: URL
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            @unknown default:
                EmptyView()
            }
        }
    }
}

// Downsampling large images
extension UIImage {
    static func downsample(imageAt url: URL, to pointSize: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
}
```

### Memory Management

```swift
// Weak references in closures
class ViewModel {
    func loadData() {
        // ❌ Creates retain cycle
        apiClient.fetch { data in
            self.handleData(data)
        }
        
        // ✅ Break retain cycle
        apiClient.fetch { [weak self] data in
            self?.handleData(data)
        }
    }
    
    func handleData(_ data: Data) { }
    let apiClient = APIClientOld()
}

class APIClientOld {
    func fetch(completion: @escaping (Data) -> Void) { }
}

// Use structured concurrency instead
@Observable
class ModernViewModel {
    func loadData() async {
        // No retain cycle concerns with async/await
        let data = await apiClient.fetch()
        handleData(data)
    }
    
    func handleData(_ data: Data) { }
    let apiClient = ModernAPIClient()
}

actor ModernAPIClient {
    func fetch() async -> Data { Data() }
}
```

---

## 11. Security

### Certificate Pinning

```swift
class PinnedURLSessionDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertificateHash: String
    
    init(pinnedHash: String) {
        self.pinnedCertificateHash = pinnedHash
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverCertificateData = SecCertificateCopyData(certificate) as Data
        let serverHash = sha256(data: serverCertificateData)
        
        if serverHash == pinnedCertificateHash {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    private func sha256(data: Data) -> String {
        // SHA256 implementation
        return ""
    }
}
```

### Biometric Authentication

```swift
import LocalAuthentication

class BiometricAuth {
    enum BiometricType {
        case none
        case faceID
        case touchID
    }
    
    var biometricType: BiometricType {
        let context = LAContext()
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return .none
        }
        
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .none
        case .none: return .none
        @unknown default: return .none
        }
    }
    
    func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else {
            return false
        }
        
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }
}
```

### Secure Data Handling

```swift
// Clear sensitive data from memory
extension String {
    mutating func secureClear() {
        self = String(repeating: " ", count: self.count)
        self = ""
    }
}

extension Data {
    mutating func secureClear() {
        resetBytes(in: 0..<count)
        removeAll()
    }
}

// Prevent screenshots in sensitive screens
class SecureWindow: UIWindow {
    override func makeKeyAndVisible() {
        super.makeKeyAndVisible()
        
        // Prevent screen capture
        let textField = UITextField()
        textField.isSecureTextEntry = true
        let secureView = textField.subviews.first!
        secureView.subviews.forEach { $0.removeFromSuperview() }
        
        addSubview(secureView)
        secureView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            secureView.topAnchor.constraint(equalTo: topAnchor),
            secureView.bottomAnchor.constraint(equalTo: bottomAnchor),
            secureView.leadingAnchor.constraint(equalTo: leadingAnchor),
            secureView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        layer.superlayer?.addSublayer(secureView.layer)
        secureView.layer.sublayers?.last?.addSublayer(layer)
    }
}
```

---

## 12. App Store Guidelines

### Common Rejection Reasons

1. **Crashes and bugs** — Test thoroughly on all supported devices
2. **Incomplete information** — Fill out all App Store Connect fields
3. **Placeholder content** — Remove all "lorem ipsum" and test data
4. **Broken links** — Verify all URLs work
5. **Privacy violations** — Include accurate privacy labels
6. **Guideline 4.2** — Minimum functionality (app must do something useful)
7. **Missing login credentials** — Provide demo account for review

### Required Privacy Disclosures

In `Info.plist`:

```xml
<!-- Camera -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to take profile photos</string>

<!-- Photo Library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo access to let you choose profile pictures</string>

<!-- Location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show nearby restaurants</string>

<!-- Face ID -->
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely unlock the app</string>

<!-- Microphone -->
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice messages</string>

<!-- Contacts -->
<key>NSContactsUsageDescription</key>
<string>We need contacts access to help you find friends</string>

<!-- Calendars -->
<key>NSCalendarsUsageDescription</key>
<string>We need calendar access to add events</string>
```

### App Tracking Transparency

```swift
import AppTrackingTransparency
import AdSupport

func requestTrackingPermission() async -> ATTrackingManager.AuthorizationStatus {
    return await ATTrackingManager.requestTrackingAuthorization()
}

// Check before tracking
func trackEvent(_ event: String) {
    guard ATTrackingManager.trackingAuthorizationStatus == .authorized else {
        return
    }
    
    let idfa = ASIdentifierManager.shared().advertisingIdentifier
    // Send tracking event with IDFA
}
```

---

## 13. CI/CD with GitHub Actions

### Basic iOS Workflow

```yaml
# .github/workflows/ios.yml
name: iOS CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-14
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app
      
      - name: Cache SPM
        uses: actions/cache@v4
        with:
          path: |
            ~/Library/Caches/org.swift.swiftpm
            ~/Library/Developer/Xcode/DerivedData
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
          restore-keys: ${{ runner.os }}-spm-
      
      - name: Build
        run: |
          xcodebuild build \
            -scheme MyApp \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -configuration Debug \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO
      
      - name: Test
        run: |
          xcodebuild test \
            -scheme MyApp \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            -configuration Debug \
            -resultBundlePath TestResults \
            CODE_SIGN_IDENTITY="" \
            CODE_SIGNING_REQUIRED=NO
      
      - name: Upload Test Results
        uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: test-results
          path: TestResults

  lint:
    runs-on: macos-14
    
    steps:
      - uses: actions/checkout@v4
      
      - name: SwiftLint
        run: |
          brew install swiftlint
          swiftlint lint --reporter github-actions-logging
```

### TestFlight Deployment

```yaml
# .github/workflows/deploy.yml
name: Deploy to TestFlight

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-14
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.2.app
      
      - name: Install Certificates
        env:
          P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # Create keychain
          security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          
          # Import certificates
          echo "${{ secrets.DISTRIBUTION_CERTIFICATE }}" | base64 --decode > cert.p12
          security import cert.p12 -k build.keychain -P "$P12_PASSWORD" -T /usr/bin/codesign
          
          # Set keychain settings
          security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" build.keychain
      
      - name: Install Provisioning Profile
        run: |
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          echo "${{ secrets.PROVISIONING_PROFILE }}" | base64 --decode > ~/Library/MobileDevice/Provisioning\ Profiles/profile.mobileprovision
      
      - name: Build Archive
        run: |
          xcodebuild archive \
            -scheme MyApp \
            -configuration Release \
            -archivePath MyApp.xcarchive \
            -destination 'generic/platform=iOS'
      
      - name: Export IPA
        run: |
          xcodebuild -exportArchive \
            -archivePath MyApp.xcarchive \
            -exportPath ./build \
            -exportOptionsPlist ExportOptions.plist
      
      - name: Upload to TestFlight
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.ASC_KEY }}
        run: |
          xcrun altool --upload-app \
            -f ./build/MyApp.ipa \
            -t ios \
            --apiKey ${{ secrets.ASC_KEY_ID }} \
            --apiIssuer ${{ secrets.ASC_ISSUER_ID }}
```

---

## 14. Essential Tools

### SwiftLint Configuration

```yaml
# .swiftlint.yml
disabled_rules:
  - line_length
  - trailing_whitespace

opt_in_rules:
  - empty_count
  - empty_string
  - fatal_error_message
  - first_where
  - force_unwrapping
  - implicitly_unwrapped_optional
  - last_where
  - modifier_order
  - overridden_super_call
  - private_action
  - private_outlet
  - prohibited_super_call
  - redundant_nil_coalescing
  - unused_import
  - vertical_whitespace_closing_braces

excluded:
  - Pods
  - Packages
  - */Generated/*

force_cast: error
force_try: error

identifier_name:
  min_length:
    warning: 2
  excluded:
    - id
    - x
    - y
    - z

type_body_length:
  warning: 300
  error: 500

file_length:
  warning: 500
  error: 1000

function_body_length:
  warning: 50
  error: 100

custom_rules:
  no_print:
    name: "No print statements"
    regex: "print\\("
    message: "Use Logger instead of print"
    severity: warning
```

### SwiftFormat Configuration

```swift
// .swiftformat
--indent 4
--indentcase true
--trimwhitespace always
--voidtype void
--nospaceoperators ...,..<
--ifdef no-indent
--xcodeindentation enabled
--maxwidth 120
--wraparguments before-first
--wrapparameters before-first
--wrapcollections before-first
--funcattributes prev-line
--typeattributes prev-line
--varattributes same-line

--disable redundantReturn,redundantParens
--enable isEmpty,sortedImports,blankLinesBetweenScopes
```

---

## Quick Reference Checklists

### Pre-Release Checklist

- [ ] All tests passing
- [ ] No compiler warnings
- [ ] SwiftLint clean
- [ ] Tested on all target devices
- [ ] Tested on minimum iOS version
- [ ] Dark mode tested
- [ ] Dynamic Type tested
- [ ] VoiceOver tested
- [ ] Network error handling tested
- [ ] Offline mode tested (if applicable)
- [ ] Memory profiled (no leaks)
- [ ] Privacy labels updated
- [ ] App Store screenshots ready
- [ ] Release notes written
- [ ] Analytics events verified
- [ ] Crash reporting configured

### Code Review Checklist

- [ ] Logic is correct
- [ ] Error handling is complete
- [ ] No force unwrapping
- [ ] No retain cycles
- [ ] Accessibility labels present
- [ ] Localization ready
- [ ] Unit tests added/updated
- [ ] Documentation updated
- [ ] No hardcoded strings
- [ ] No sensitive data logged

---

*End of iOS Development Best Practices Guide*

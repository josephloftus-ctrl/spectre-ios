# SwiftUI Masterclass

A comprehensive guide to building modern iOS applications with SwiftUI.

---

## 1. Foundation: Understanding SwiftUI's Philosophy

SwiftUI is a declarative UI framework. You describe *what* you want, not *how* to build it. The framework handles the rendering, diffing, and updates.

```swift
// Imperative (UIKit approach)
let label = UILabel()
label.text = "Hello"
label.textColor = .blue
view.addSubview(label)

// Declarative (SwiftUI approach)
Text("Hello")
    .foregroundColor(.blue)
```

### Core Principles

1. **Views are structs** — lightweight value types, not reference types
2. **Views are a function of state** — UI = f(state)
3. **Single source of truth** — state drives everything
4. **Composition over inheritance** — build complex views from simple ones

---

## 2. Views and Modifiers

### The View Protocol

Every SwiftUI view conforms to the `View` protocol:

```swift
protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Self.Body { get }
}
```

### Basic Views

```swift
// Text
Text("Hello, World!")
Text(verbatim: "Literal string")  // No localization
Text("Price: \(price, format: .currency(code: "USD"))")

// Images
Image(systemName: "star.fill")
Image("custom-image")
    .resizable()
    .aspectRatio(contentMode: .fit)

// Shapes
Rectangle()
RoundedRectangle(cornerRadius: 12)
Circle()
Capsule()

// Spacers and Dividers
Spacer()           // Flexible space
Spacer(minLength: 20)
Divider()          // Visual separator
```

### Modifier Order Matters

Modifiers wrap views in new views. Order is significant:

```swift
// These produce different results:
Text("Hello")
    .padding()
    .background(.blue)    // Blue background includes padding

Text("Hello")
    .background(.blue)    // Blue background only around text
    .padding()
```

### Common Modifiers

```swift
Text("Styled Text")
    // Typography
    .font(.title)
    .fontWeight(.bold)
    .fontDesign(.rounded)
    .foregroundStyle(.primary)
    
    // Layout
    .padding()
    .padding(.horizontal, 16)
    .frame(width: 200, height: 100)
    .frame(maxWidth: .infinity, alignment: .leading)
    
    // Appearance
    .background(.blue)
    .clipShape(RoundedRectangle(cornerRadius: 8))
    .shadow(radius: 4)
    .opacity(0.8)
    
    // Interaction
    .onTapGesture { }
    .disabled(isDisabled)
```

### Custom Modifiers

```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// Usage
Text("Card Content")
    .cardStyle()
```

---

## 3. Layout System

### Stacks

```swift
// Horizontal
HStack(alignment: .top, spacing: 12) {
    Text("Left")
    Text("Right")
}

// Vertical
VStack(alignment: .leading, spacing: 8) {
    Text("Top")
    Text("Bottom")
}

// Layered (z-axis)
ZStack(alignment: .bottomTrailing) {
    Image("background")
    Text("Overlay")
}
```

### Lazy Stacks (for long lists)

```swift
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### Grids

```swift
// Fixed columns
let columns = [
    GridItem(.fixed(100)),
    GridItem(.fixed(100)),
    GridItem(.fixed(100))
]

// Flexible columns
let columns = [
    GridItem(.flexible(minimum: 80, maximum: 150)),
    GridItem(.flexible(minimum: 80, maximum: 150))
]

// Adaptive (as many as fit)
let columns = [
    GridItem(.adaptive(minimum: 100, maximum: 200))
]

LazyVGrid(columns: columns, spacing: 16) {
    ForEach(items) { item in
        ItemCell(item: item)
    }
}
```

### GeometryReader

Access parent size and position:

```swift
GeometryReader { geometry in
    VStack {
        Text("Width: \(geometry.size.width)")
        Text("Height: \(geometry.size.height)")
    }
    .frame(width: geometry.size.width * 0.8)
}
```

**Warning:** GeometryReader takes all available space. Use sparingly.

### Layout Protocol (iOS 16+)

Create custom layouts:

```swift
struct RadialLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let radius = min(bounds.width, bounds.height) / 2
        let angle = Angle.degrees(360 / Double(subviews.count)).radians
        
        for (index, subview) in subviews.enumerated() {
            let x = bounds.midX + radius * cos(angle * Double(index) - .pi / 2)
            let y = bounds.midY + radius * sin(angle * Double(index) - .pi / 2)
            subview.place(at: CGPoint(x: x, y: y), anchor: .center)
        }
    }
}
```

---

## 4. State Management

This is the most critical section. Master this.

### Property Wrappers Overview

| Wrapper | Ownership | Source | Use Case |
|---------|-----------|--------|----------|
| `@State` | View owns it | Local | Simple view state |
| `@Binding` | Parent owns it | External | Two-way connection |
| `@StateObject` | View owns it | Local | ObservableObject lifecycle |
| `@ObservedObject` | Parent owns it | External | ObservableObject reference |
| `@EnvironmentObject` | Environment | Injected | Shared app state |
| `@Environment` | System | System | System values |
| `@Observable` (iOS 17+) | Varies | Varies | Modern observation |

### @State

For simple, view-local state:

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack {
            Text("Count: \(count)")
            Button("Increment") {
                count += 1
            }
        }
    }
}
```

**Rules:**
- Always mark `private`
- Only for value types
- View owns the state
- Survives view rebuilds

### @Binding

Two-way connection to external state:

```swift
struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(title, isOn: $isOn)
    }
}

struct ParentView: View {
    @State private var notificationsEnabled = true
    
    var body: some View {
        ToggleRow(title: "Notifications", isOn: $notificationsEnabled)
    }
}
```

Create constant bindings for previews:

```swift
ToggleRow(title: "Test", isOn: .constant(true))
```

### ObservableObject Pattern (iOS 13-16)

```swift
class UserViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var isLoading = false
    
    func save() async {
        isLoading = true
        defer { isLoading = false }
        // Save logic
    }
}
```

### @StateObject vs @ObservedObject

```swift
struct ParentView: View {
    // Use @StateObject when THIS view creates and owns the object
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        ChildView(viewModel: viewModel)
    }
}

struct ChildView: View {
    // Use @ObservedObject when receiving from parent
    @ObservedObject var viewModel: UserViewModel
    
    var body: some View {
        Text(viewModel.name)
    }
}
```

**Critical:** Using `@StateObject` when you should use `@ObservedObject` (or vice versa) causes bugs. `@StateObject` creates a new instance; `@ObservedObject` expects an existing one.

### @EnvironmentObject

For deeply nested state sharing:

```swift
class AppState: ObservableObject {
    @Published var user: User?
    @Published var theme: Theme = .light
}

// Inject at root
@main
struct MyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// Access anywhere in hierarchy
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Text(appState.user?.name ?? "Guest")
    }
}
```

### @Observable (iOS 17+) — The Modern Way

```swift
@Observable
class UserViewModel {
    var name = ""
    var email = ""
    var isLoading = false
    
    func save() async {
        isLoading = true
        defer { isLoading = false }
        // Save logic
    }
}

struct ContentView: View {
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        // Automatic fine-grained observation
        // Only rebuilds when accessed properties change
        Form {
            TextField("Name", text: $viewModel.name)
            TextField("Email", text: $viewModel.email)
        }
    }
}
```

**Benefits of @Observable:**
- Fine-grained updates (only affected views rebuild)
- Simpler mental model
- Use `@State` for owned objects
- Pass directly or through environment

```swift
// Environment with @Observable
struct ContentView: View {
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        ChildView()
            .environment(viewModel)  // Note: .environment, not .environmentObject
    }
}

struct ChildView: View {
    @Environment(UserViewModel.self) var viewModel
    
    var body: some View {
        Text(viewModel.name)
    }
}
```

### @Environment for System Values

```swift
struct AdaptiveView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack {
            if colorScheme == .dark {
                Text("Dark Mode")
            }
            
            Button("Close") {
                dismiss()
            }
            
            Button("Open Website") {
                openURL(URL(string: "https://apple.com")!)
            }
        }
    }
}
```

---

## 5. Navigation

### NavigationStack (iOS 16+)

```swift
struct ContentView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            List(items) { item in
                NavigationLink(value: item) {
                    Text(item.name)
                }
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
            .navigationDestination(for: Category.self) { category in
                CategoryView(category: category)
            }
            .navigationTitle("Items")
        }
    }
}
```

### Programmatic Navigation

```swift
struct ContentView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                Button("Go to Item") {
                    path.append(Item(id: 1, name: "Test"))
                }
                
                Button("Go Deep") {
                    path.append(Item(id: 1, name: "First"))
                    path.append(Item(id: 2, name: "Second"))
                    path.append(Item(id: 3, name: "Third"))
                }
                
                Button("Pop to Root") {
                    path.removeLast(path.count)
                }
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
        }
    }
}
```

### NavigationSplitView (iPad/Mac)

```swift
struct ContentView: View {
    @State private var selectedCategory: Category?
    @State private var selectedItem: Item?
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(categories, selection: $selectedCategory) { category in
                Text(category.name)
            }
            .navigationTitle("Categories")
        } content: {
            // Content (middle column)
            if let category = selectedCategory {
                List(category.items, selection: $selectedItem) { item in
                    Text(item.name)
                }
            } else {
                ContentUnavailableView("Select a Category", systemImage: "folder")
            }
        } detail: {
            // Detail (right column)
            if let item = selectedItem {
                ItemDetailView(item: item)
            } else {
                ContentUnavailableView("Select an Item", systemImage: "doc")
            }
        }
    }
}
```

### Sheets and Modals

```swift
struct ContentView: View {
    @State private var showSheet = false
    @State private var showFullScreen = false
    @State private var selectedItem: Item?
    
    var body: some View {
        VStack {
            Button("Show Sheet") {
                showSheet = true
            }
            
            Button("Show Full Screen") {
                showFullScreen = true
            }
            
            Button("Show Item") {
                selectedItem = Item(id: 1, name: "Test")
            }
        }
        // Boolean-triggered sheet
        .sheet(isPresented: $showSheet) {
            SheetContent()
        }
        // Full screen cover
        .fullScreenCover(isPresented: $showFullScreen) {
            FullScreenContent()
        }
        // Item-triggered sheet (nil = dismissed)
        .sheet(item: $selectedItem) { item in
            ItemDetailView(item: item)
        }
    }
}
```

### Dismiss Sheets

```swift
struct SheetContent: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Text("Sheet Content")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            // Save and dismiss
                            dismiss()
                        }
                    }
                }
        }
    }
}
```

---

## 6. Lists and Collections

### Basic List

```swift
struct ItemListView: View {
    let items: [Item]
    
    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }
}
```

### List with Sections

```swift
List {
    Section("Favorites") {
        ForEach(favorites) { item in
            ItemRow(item: item)
        }
    }
    
    Section {
        ForEach(others) { item in
            ItemRow(item: item)
        }
    } header: {
        Text("Other Items")
    } footer: {
        Text("\(others.count) items")
    }
}
```

### Swipe Actions

```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                Button {
                    archive(item)
                } label: {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .leading) {
                Button {
                    toggleFavorite(item)
                } label: {
                    Label("Favorite", systemImage: "star")
                }
                .tint(.yellow)
            }
    }
}
```

### List Styles

```swift
List { ... }
    .listStyle(.plain)           // No separators, no background
    .listStyle(.inset)           // Rounded corners
    .listStyle(.insetGrouped)    // Settings-style
    .listStyle(.grouped)         // Grouped sections
    .listStyle(.sidebar)         // Mac/iPad sidebar
```

### Pull to Refresh

```swift
List(items) { item in
    ItemRow(item: item)
}
.refreshable {
    await loadItems()
}
```

### Search

```swift
struct SearchableList: View {
    @State private var searchText = ""
    let items: [Item]
    
    var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List(filteredItems) { item in
            ItemRow(item: item)
        }
        .searchable(text: $searchText, prompt: "Search items")
    }
}
```

### Selection

```swift
struct SelectableList: View {
    @State private var selection: Set<Item.ID> = []
    let items: [Item]
    
    var body: some View {
        List(items, selection: $selection) { item in
            ItemRow(item: item)
        }
        .toolbar {
            EditButton()
        }
    }
}
```

---

## 7. Forms and Input

### Form Basics

```swift
struct SettingsView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var notificationsEnabled = true
    @State private var selectedTheme = Theme.system
    @State private var fontSize = 14.0
    @State private var birthday = Date()
    @State private var accentColor = Color.blue
    
    var body: some View {
        Form {
            Section("Account") {
                TextField("Username", text: $username)
                SecureField("Password", text: $password)
            }
            
            Section("Preferences") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                
                Picker("Theme", selection: $selectedTheme) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                
                Slider(value: $fontSize, in: 10...24, step: 1) {
                    Text("Font Size")
                } minimumValueLabel: {
                    Text("10")
                } maximumValueLabel: {
                    Text("24")
                }
                
                Stepper("Font Size: \(Int(fontSize))", value: $fontSize, in: 10...24)
            }
            
            Section {
                DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                ColorPicker("Accent Color", selection: $accentColor)
            }
        }
    }
}
```

### TextField Variations

```swift
// Basic
TextField("Name", text: $name)

// With prompt
TextField("Enter name", text: $name, prompt: Text("Your full name"))

// Multiline
TextField("Bio", text: $bio, axis: .vertical)
    .lineLimit(3...6)

// Styled
TextField("Amount", value: $amount, format: .currency(code: "USD"))
TextField("Date", value: $date, format: .dateTime)

// With keyboard type
TextField("Email", text: $email)
    .textContentType(.emailAddress)
    .keyboardType(.emailAddress)
    .autocapitalization(.none)

// With validation state
TextField("Email", text: $email)
    .border(isValidEmail ? .clear : .red)
```

### Focus Management

```swift
struct LoginView: View {
    enum Field: Hashable {
        case email, password
    }
    
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?
    
    var body: some View {
        Form {
            TextField("Email", text: $email)
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .password
                }
            
            SecureField("Password", text: $password)
                .focused($focusedField, equals: .password)
                .submitLabel(.done)
                .onSubmit {
                    login()
                }
            
            Button("Login") {
                login()
            }
        }
        .onAppear {
            focusedField = .email
        }
    }
    
    func login() {
        // Login logic
    }
}
```

---

## 8. Animations

### Implicit Animations

```swift
struct AnimatedView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            Rectangle()
                .fill(.blue)
                .frame(width: isExpanded ? 200 : 100, height: 100)
                .animation(.easeInOut(duration: 0.3), value: isExpanded)
            
            Button("Toggle") {
                isExpanded.toggle()
            }
        }
    }
}
```

### Explicit Animations

```swift
Button("Toggle") {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
        isExpanded.toggle()
    }
}
```

### Animation Types

```swift
// Linear
.animation(.linear(duration: 0.3), value: state)

// Ease variations
.animation(.easeIn(duration: 0.3), value: state)
.animation(.easeOut(duration: 0.3), value: state)
.animation(.easeInOut(duration: 0.3), value: state)

// Spring
.animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: state)
.animation(.spring(duration: 0.5, bounce: 0.3), value: state)  // iOS 17+
.animation(.bouncy, value: state)  // iOS 17+
.animation(.snappy, value: state)  // iOS 17+

// Repeating
.animation(.linear(duration: 1).repeatForever(autoreverses: true), value: state)
```

### Transitions

```swift
struct TransitionExample: View {
    @State private var showDetail = false
    
    var body: some View {
        VStack {
            if showDetail {
                DetailView()
                    .transition(.slide)
                    // Or combine transitions:
                    // .transition(.scale.combined(with: .opacity))
                    // .transition(.asymmetric(insertion: .slide, removal: .opacity))
            }
            
            Button("Toggle") {
                withAnimation {
                    showDetail.toggle()
                }
            }
        }
    }
}
```

### Matched Geometry Effect

```swift
struct HeroAnimation: View {
    @Namespace private var animation
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            if isExpanded {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.blue)
                    .matchedGeometryEffect(id: "shape", in: animation)
                    .frame(width: 300, height: 400)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.blue)
                    .matchedGeometryEffect(id: "shape", in: animation)
                    .frame(width: 100, height: 100)
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }
}
```

### Phase Animator (iOS 17+)

```swift
struct PulsingView: View {
    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 100, height: 100)
            .phaseAnimator([false, true]) { content, phase in
                content
                    .scaleEffect(phase ? 1.2 : 1.0)
                    .opacity(phase ? 0.8 : 1.0)
            } animation: { phase in
                .easeInOut(duration: 0.8)
            }
    }
}
```

---

## 9. Gestures

### Basic Gestures

```swift
struct GestureExamples: View {
    @State private var taps = 0
    @State private var offset = CGSize.zero
    @State private var scale = 1.0
    @State private var angle = Angle.zero
    
    var body: some View {
        VStack {
            // Tap
            Text("Taps: \(taps)")
                .onTapGesture {
                    taps += 1
                }
                .onTapGesture(count: 2) {
                    taps = 0
                }
            
            // Long Press
            Circle()
                .fill(.blue)
                .frame(width: 100, height: 100)
                .onLongPressGesture(minimumDuration: 0.5) {
                    print("Long pressed!")
                }
            
            // Drag
            Circle()
                .fill(.green)
                .frame(width: 100, height: 100)
                .offset(offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            offset = value.translation
                        }
                        .onEnded { _ in
                            withAnimation {
                                offset = .zero
                            }
                        }
                )
            
            // Magnification
            Image(systemName: "star.fill")
                .font(.system(size: 50))
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value
                        }
                        .onEnded { _ in
                            withAnimation {
                                scale = 1.0
                            }
                        }
                )
            
            // Rotation
            Rectangle()
                .fill(.orange)
                .frame(width: 100, height: 100)
                .rotationEffect(angle)
                .gesture(
                    RotationGesture()
                        .onChanged { value in
                            angle = value
                        }
                )
        }
    }
}
```

### Combining Gestures

```swift
// Simultaneous (both at once)
.gesture(
    MagnificationGesture()
        .simultaneously(with: RotationGesture())
        .onChanged { value in
            scale = value.first ?? 1.0
            angle = value.second ?? .zero
        }
)

// Sequential (one after another)
.gesture(
    LongPressGesture()
        .sequenced(before: DragGesture())
        .onEnded { value in
            switch value {
            case .first(true):
                print("Long press completed")
            case .second(true, let drag):
                print("Dragged after long press: \(String(describing: drag))")
            default:
                break
            }
        }
)

// Exclusive (higher priority wins)
.gesture(
    TapGesture(count: 2)
        .exclusively(before: TapGesture(count: 1))
)
```

---

## 10. Async/Await Integration

### Task Modifier

```swift
struct AsyncView: View {
    @State private var items: [Item] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
        .task {
            // Automatically cancelled when view disappears
            await loadItems()
        }
        .task(id: someValue) {
            // Re-runs when someValue changes
            await loadItems()
        }
    }
    
    var someValue: String { "" }  // Placeholder
    
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await fetchItems()
        } catch {
            self.error = error
        }
    }
    
    func fetchItems() async throws -> [Item] {
        // Fetch logic
        return []
    }
}
```

### Refreshable

```swift
List(items) { item in
    ItemRow(item: item)
}
.refreshable {
    await loadItems()
}
```

### Async Button Actions

```swift
Button("Save") {
    Task {
        await save()
    }
}

// Or with loading state
struct AsyncButton: View {
    let action: () async -> Void
    let label: String
    
    @State private var isLoading = false
    
    var body: some View {
        Button {
            Task {
                isLoading = true
                defer { isLoading = false }
                await action()
            }
        } label: {
            if isLoading {
                ProgressView()
            } else {
                Text(label)
            }
        }
        .disabled(isLoading)
    }
}
```

---

## 11. Custom Components

### Building a Reusable Card

```swift
struct Card<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// Usage
Card {
    VStack(alignment: .leading) {
        Text("Title")
            .font(.headline)
        Text("Description")
            .foregroundStyle(.secondary)
    }
}
```

### Building a Custom Button Style

```swift
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(isEnabled ? Color.blue : Color.gray)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

// Usage
Button("Submit") { }
    .buttonStyle(.primary)
```

### Building a Custom Toggle Style

```swift
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundStyle(configuration.isOn ? .blue : .secondary)
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

// Usage
Toggle("Accept Terms", isOn: $accepted)
    .toggleStyle(CheckboxToggleStyle())
```

---

## 12. Previews

### Basic Previews

```swift
#Preview {
    ContentView()
}

#Preview("Dark Mode") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    ContentView()
        .dynamicTypeSize(.xxxLarge)
}
```

### Preview with State

```swift
#Preview {
    @Previewable @State var isOn = false
    
    Toggle("Setting", isOn: $isOn)
}
```

### Preview Traits

```swift
#Preview(traits: .sizeThatFitsLayout) {
    MyComponent()
}
```

---

## 13. Performance Optimization

### Avoiding Unnecessary Redraws

```swift
// Bad: Entire view rebuilds when any state changes
struct BadView: View {
    @State private var name = ""
    @State private var count = 0
    
    var body: some View {
        VStack {
            TextField("Name", text: $name)
            ExpensiveView()  // Rebuilds when name changes!
            Text("Count: \(count)")
        }
    }
}

// Good: Extract independent state
struct GoodView: View {
    var body: some View {
        VStack {
            NameField()
            ExpensiveView()  // Only rebuilds when its own dependencies change
            CountDisplay()
        }
    }
}

struct NameField: View {
    @State private var name = ""
    var body: some View {
        TextField("Name", text: $name)
    }
}

struct CountDisplay: View {
    @State private var count = 0
    var body: some View {
        Text("Count: \(count)")
    }
}

struct ExpensiveView: View {
    var body: some View {
        Text("Expensive")
    }
}
```

### Lazy Loading

```swift
// Use LazyVStack/LazyHStack for long lists
ScrollView {
    LazyVStack {
        ForEach(items) { item in
            ItemRow(item: item)
        }
    }
}

// Lazy grids
LazyVGrid(columns: columns) {
    ForEach(items) { item in
        ItemCell(item: item)
    }
}
```

### Task Cancellation

```swift
struct SearchView: View {
    @State private var query = ""
    @State private var results: [SearchResult] = []
    
    var body: some View {
        List(results) { result in
            Text(result.title)
        }
        .searchable(text: $query)
        .task(id: query) {
            // Debounce
            try? await Task.sleep(for: .milliseconds(300))
            
            // Check if cancelled (user typed more)
            guard !Task.isCancelled else { return }
            
            results = await search(query: query)
        }
    }
    
    func search(query: String) async -> [SearchResult] {
        return []
    }
}

struct SearchResult: Identifiable {
    let id: UUID
    let title: String
}
```

---

## 14. Common Patterns

### Coordinator Pattern for Complex Navigation

```swift
@Observable
class AppCoordinator {
    var path = NavigationPath()
    var sheet: Sheet?
    
    enum Sheet: Identifiable {
        case settings
        case profile(User)
        
        var id: String {
            switch self {
            case .settings: return "settings"
            case .profile(let user): return "profile-\(user.id)"
            }
        }
    }
    
    func showSettings() {
        sheet = .settings
    }
    
    func showProfile(_ user: User) {
        sheet = .profile(user)
    }
    
    func navigate(to destination: any Hashable) {
        path.append(destination)
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
```

### Dependency Injection

```swift
// Protocol
protocol ItemRepository {
    func fetchItems() async throws -> [Item]
    func save(_ item: Item) async throws
}

// Implementation
class APIItemRepository: ItemRepository {
    func fetchItems() async throws -> [Item] {
        // Real API call
        return []
    }
    
    func save(_ item: Item) async throws {
        // Real API call
    }
}

// Mock for previews/tests
class MockItemRepository: ItemRepository {
    var items: [Item] = []
    
    func fetchItems() async throws -> [Item] {
        items
    }
    
    func save(_ item: Item) async throws {
        items.append(item)
    }
}

// ViewModel
@Observable
class ItemViewModel {
    private let repository: ItemRepository
    var items: [Item] = []
    
    init(repository: ItemRepository = APIItemRepository()) {
        self.repository = repository
    }
    
    func load() async {
        items = (try? await repository.fetchItems()) ?? []
    }
}
```

### Error Handling Pattern

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
}

@Observable
class ViewModel {
    var state: LoadingState<[Item]> = .idle
    
    func load() async {
        state = .loading
        
        do {
            let items = try await fetchItems()
            state = .loaded(items)
        } catch {
            state = .error(error)
        }
    }
    
    func fetchItems() async throws -> [Item] {
        return []
    }
}

struct ContentView: View {
    @State private var viewModel = ViewModel()
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear
            case .loading:
                ProgressView()
            case .loaded(let items):
                List(items) { item in
                    ItemRow(item: item)
                }
            case .error(let error):
                ContentUnavailableView {
                    Label("Error", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("Retry") {
                        Task { await viewModel.load() }
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
```

---

## Quick Reference

### State Management Decision Tree

1. **Simple value, one view?** → `@State`
2. **Value from parent?** → `@Binding`
3. **Object, this view creates it?** → `@StateObject` (pre-iOS 17) or `@State` with `@Observable` (iOS 17+)
4. **Object from parent?** → `@ObservedObject` (pre-iOS 17) or just pass it (iOS 17+)
5. **Shared across many views?** → `@EnvironmentObject` or `.environment()` with `@Observable`
6. **System value?** → `@Environment`

### Common Mistakes to Avoid

1. Using `@ObservedObject` when you should use `@StateObject`
2. Heavy computation in `body` (use computed properties or cache)
3. Not using `LazyVStack/LazyHStack` for long lists
4. Forgetting to handle loading and error states
5. Over-using `GeometryReader`
6. Not testing on real devices
7. Ignoring accessibility

---

*End of SwiftUI Masterclass*

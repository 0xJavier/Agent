---
name: swiftui-ios
description: Build production-quality iOS applications with SwiftUI. Use when the user asks to create iOS apps, SwiftUI views, iOS components, mobile interfaces, or needs help with Swift/SwiftUI patterns. Covers app architecture (MVVM, TCA), navigation, state management, animations, accessibility, and modern iOS 17+ APIs. Triggers on requests for iPhone/iPad apps, SwiftUI layouts, iOS widgets, or Swift code for Apple platforms.
---

# SwiftUI iOS Development

Build modern, production-quality iOS applications using SwiftUI and Swift best practices.

## Core Principles

### SwiftUI-First Approach
- Use SwiftUI for all new UI code; avoid UIKit unless absolutely necessary
- Leverage declarative syntax for readable, maintainable views
- Embrace the reactive data flow with `@State`, `@Binding`, `@Observable`

### Architecture
Default to **MVVM with @Observable** (iOS 17+):

```swift
@Observable
final class TaskListViewModel {
    var tasks: [Task] = []
    var isLoading = false
    var errorMessage: String?
    
    func loadTasks() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            tasks = try await taskService.fetchTasks()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct TaskListView: View {
    @State private var viewModel = TaskListViewModel()
    
    var body: some View {
        List(viewModel.tasks) { task in
            TaskRow(task: task)
        }
        .overlay { if viewModel.isLoading { ProgressView() } }
        .task { await viewModel.loadTasks() }
    }
}
```

For complex apps, consider **The Composable Architecture (TCA)** - see [references/tca-patterns.md](references/tca-patterns.md).

## State Management Quick Reference

| Property Wrapper | Use Case | Scope |
|-----------------|----------|-------|
| `@State` | View-local value types | Single view |
| `@Binding` | Two-way connection to parent's state | Child views |
| `@Observable` | Reference type view models (iOS 17+) | Shared across views |
| `@Environment` | Dependency injection, system values | View hierarchy |
| `@AppStorage` | UserDefaults persistence | App-wide |

### Pre-iOS 17 Compatibility
Use `@StateObject` + `ObservableObject` instead of `@Observable`:

```swift
final class ViewModel: ObservableObject {
    @Published var data: [Item] = []
}

struct ContentView: View {
    @StateObject private var viewModel = ViewModel()
}
```

## Navigation Patterns (iOS 16+)

Use `NavigationStack` with type-safe navigation:

```swift
struct AppNavigation: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: Task.self) { task in
                    TaskDetailView(task: task)
                }
                .navigationDestination(for: Profile.self) { profile in
                    ProfileView(profile: profile)
                }
        }
    }
}
```

For tab-based apps:
```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab("Settings", systemImage: "gear") { SettingsView() }
}
```

## Layout Essentials

### Adaptive Layouts
```swift
ViewThatFits {
    HStack { /* horizontal layout */ }
    VStack { /* fallback vertical */ }
}
```

### Grid Layouts
```swift
LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
    ForEach(items) { item in
        CardView(item: item)
    }
}
```

### Safe Area & Geometry
```swift
GeometryReader { geometry in
    content
        .frame(width: geometry.size.width * 0.8)
}
.safeAreaInset(edge: .bottom) {
    ActionBar()
}
```

## Animation Patterns

### Spring Animations (Default Choice)
```swift
withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
    isExpanded.toggle()
}
```

### Matched Geometry for Transitions
```swift
@Namespace private var animation

// Source
Image(item.image)
    .matchedGeometryEffect(id: item.id, in: animation)

// Destination (in sheet/detail view)
Image(item.image)
    .matchedGeometryEffect(id: item.id, in: animation)
```

### Phase Animations (iOS 17+)
```swift
PhaseAnimator([false, true], trigger: trigger) { phase in
    content
        .scaleEffect(phase ? 1.2 : 1.0)
        .opacity(phase ? 0.8 : 1.0)
}
```

## Networking & Data

### Modern Async/Await Pattern
```swift
actor NetworkService {
    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: endpoint.request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

### SwiftData (iOS 17+)
```swift
@Model
final class Task {
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    
    init(title: String) {
        self.title = title
        self.isCompleted = false
        self.createdAt = .now
    }
}

struct TaskListView: View {
    @Query(sort: \Task.createdAt, order: .reverse) 
    private var tasks: [Task]
    @Environment(\.modelContext) private var context
    
    func addTask(_ title: String) {
        context.insert(Task(title: title))
    }
}
```

## Accessibility Requirements

**Always include:**
```swift
Button(action: purchase) {
    Label("Buy Now", systemImage: "cart")
}
.accessibilityLabel("Purchase item for \(price)")
.accessibilityHint("Double tap to complete purchase")

// For custom controls
CustomSlider(value: $volume)
    .accessibilityValue("\(Int(volume * 100)) percent")
    .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment: volume = min(1, volume + 0.1)
        case .decrement: volume = max(0, volume - 0.1)
        @unknown default: break
        }
    }
```

## Testing Patterns

See [references/testing-guide.md](references/testing-guide.md) for comprehensive testing strategies.

Quick example:
```swift
@Test func taskCompletion() async {
    let viewModel = TaskListViewModel()
    viewModel.tasks = [Task(title: "Test")]
    
    viewModel.toggleComplete(viewModel.tasks[0])
    
    #expect(viewModel.tasks[0].isCompleted == true)
}
```

## Common Gotchas

1. **Don't force unwrap** - Use `guard let` or nil coalescing
2. **Avoid heavy work in body** - Move to `.task` or view model
3. **Use `@MainActor`** for UI updates from async contexts
4. **Prefer `task` over `onAppear`** for async work (automatic cancellation)
5. **Test on real devices** - Simulator doesn't catch all performance issues

## Reference Files

- [Architecture Patterns (MVVM, TCA)](references/architecture-patterns.md) - Detailed architecture guidance
- [TCA Patterns](references/tca-patterns.md) - Composable Architecture examples
- [Testing Guide](references/testing-guide.md) - Unit, integration, and UI testing
- [Performance Optimization](references/performance.md) - Profiling and optimization tips

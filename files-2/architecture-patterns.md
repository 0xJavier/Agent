# SwiftUI Architecture Patterns

## MVVM with @Observable (Recommended for iOS 17+)

The modern approach using Swift's observation framework.

### Basic Structure

```swift
// Model
struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
}

// ViewModel
@Observable
final class UserProfileViewModel {
    // State
    var user: User?
    var isLoading = false
    var error: Error?
    
    // Dependencies (injected)
    private let userService: UserServiceProtocol
    
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
    
    // Actions
    func loadUser(id: UUID) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            user = try await userService.fetchUser(id: id)
        } catch {
            self.error = error
        }
    }
    
    func updateName(_ newName: String) async throws {
        guard var currentUser = user else { return }
        currentUser.name = newName
        user = try await userService.updateUser(currentUser)
    }
}

// View
struct UserProfileView: View {
    let userId: UUID
    @State private var viewModel = UserProfileViewModel()
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let user = viewModel.user {
                UserContent(user: user)
            } else if let error = viewModel.error {
                ErrorView(error: error, retry: { Task { await viewModel.loadUser(id: userId) } })
            }
        }
        .task { await viewModel.loadUser(id: userId) }
    }
}
```

### Dependency Injection Pattern

```swift
// Protocol for testability
protocol UserServiceProtocol: Sendable {
    func fetchUser(id: UUID) async throws -> User
    func updateUser(_ user: User) async throws -> User
}

// Production implementation
final class UserService: UserServiceProtocol {
    func fetchUser(id: UUID) async throws -> User {
        // Real network call
    }
    
    func updateUser(_ user: User) async throws -> User {
        // Real network call
    }
}

// Mock for testing/previews
final class MockUserService: UserServiceProtocol {
    var mockUser = User(id: UUID(), name: "Test", email: "test@example.com")
    
    func fetchUser(id: UUID) async throws -> User { mockUser }
    func updateUser(_ user: User) async throws -> User { user }
}

// Environment-based injection
extension EnvironmentValues {
    @Entry var userService: UserServiceProtocol = UserService()
}

struct UserProfileView: View {
    @Environment(\.userService) private var userService
    @State private var viewModel: UserProfileViewModel?
    
    var body: some View {
        content
            .onAppear {
                viewModel = UserProfileViewModel(userService: userService)
            }
    }
}
```

## Repository Pattern

For apps with multiple data sources (network + cache):

```swift
protocol TaskRepositoryProtocol {
    func getTasks() async throws -> [Task]
    func saveTask(_ task: Task) async throws
}

final class TaskRepository: TaskRepositoryProtocol {
    private let networkService: NetworkService
    private let cacheService: CacheService
    
    func getTasks() async throws -> [Task] {
        // Try cache first
        if let cached = try? await cacheService.getTasks(), !cached.isEmpty {
            // Return cached, refresh in background
            Task { try? await refreshFromNetwork() }
            return cached
        }
        
        // Fetch from network
        let tasks = try await networkService.fetchTasks()
        try? await cacheService.saveTasks(tasks)
        return tasks
    }
    
    private func refreshFromNetwork() async throws {
        let tasks = try await networkService.fetchTasks()
        try await cacheService.saveTasks(tasks)
    }
}
```

## Coordinator Pattern for Navigation

For complex navigation flows:

```swift
@Observable
final class AppCoordinator {
    var path = NavigationPath()
    var sheet: Sheet?
    var fullScreenCover: FullScreenCover?
    
    enum Sheet: Identifiable {
        case settings
        case newTask
        
        var id: String { String(describing: self) }
    }
    
    enum FullScreenCover: Identifiable {
        case onboarding
        case imageViewer(URL)
        
        var id: String { String(describing: self) }
    }
    
    // Navigation actions
    func showTaskDetail(_ task: Task) {
        path.append(task)
    }
    
    func showSettings() {
        sheet = .settings
    }
    
    func dismissSheet() {
        sheet = nil
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
}

struct CoordinatedApp: View {
    @State private var coordinator = AppCoordinator()
    
    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView()
                .navigationDestination(for: Task.self) { task in
                    TaskDetailView(task: task)
                }
        }
        .sheet(item: $coordinator.sheet) { sheet in
            switch sheet {
            case .settings: SettingsView()
            case .newTask: NewTaskView()
            }
        }
        .environment(coordinator)
    }
}
```

## Feature Modules Pattern

For larger apps, organize by feature:

```
App/
├── Core/
│   ├── Network/
│   ├── Storage/
│   └── Extensions/
├── Features/
│   ├── Home/
│   │   ├── HomeView.swift
│   │   ├── HomeViewModel.swift
│   │   └── Components/
│   ├── Tasks/
│   │   ├── TaskListView.swift
│   │   ├── TaskDetailView.swift
│   │   ├── TaskViewModel.swift
│   │   └── Models/
│   └── Settings/
└── App/
    ├── AppDelegate.swift
    └── ContentView.swift
```

Each feature is self-contained with its own views, view models, and models.

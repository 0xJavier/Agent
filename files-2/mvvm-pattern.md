# MVVM Pattern in SwiftUI

## Table of Contents

1. [Overview](#overview)
2. [Basic MVVM Structure](#basic-mvvm-structure)
3. [iOS 17+ with @Observable](#ios-17-with-observable)
4. [iOS 14-16 with ObservableObject](#ios-14-16-with-observableobject)
5. [Dependency Injection](#dependency-injection)
6. [Testing ViewModels](#testing-viewmodels)

## Overview

MVVM (Model-View-ViewModel) separates concerns:
- **Model**: Data structures and business logic
- **View**: SwiftUI views (declarative UI)
- **ViewModel**: Transforms model data for display, handles user actions

## Basic MVVM Structure

```
Feature/
├── Models/
│   └── User.swift
├── ViewModels/
│   └── UserViewModel.swift
└── Views/
    └── UserView.swift
```

## iOS 17+ with @Observable

The modern approach using the Observation framework:

### Model

```swift
struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var avatarURL: URL?
}
```

### ViewModel

```swift
import Observation

@Observable
final class UserViewModel {
    // MARK: - State
    private(set) var users: [User] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    
    var searchText = ""
    
    var filteredUsers: [User] {
        guard !searchText.isEmpty else { return users }
        return users.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Dependencies
    private let userService: UserServiceProtocol
    
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
    
    // MARK: - Actions
    func loadUsers() async {
        isLoading = true
        error = nil
        
        do {
            users = try await userService.fetchUsers()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func deleteUser(_ user: User) async {
        do {
            try await userService.delete(user)
            users.removeAll { $0.id == user.id }
        } catch {
            self.error = error
        }
    }
}
```

### View

```swift
struct UserListView: View {
    @State private var viewModel = UserViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                } else if let error = viewModel.error {
                    ErrorView(error: error, retry: { Task { await viewModel.loadUsers() } })
                } else {
                    userList
                }
            }
            .navigationTitle("Users")
            .searchable(text: $viewModel.searchText)
            .task {
                await viewModel.loadUsers()
            }
        }
    }
    
    private var userList: some View {
        List {
            ForEach(viewModel.filteredUsers) { user in
                UserRow(user: user)
            }
            .onDelete { indexSet in
                Task {
                    for index in indexSet {
                        await viewModel.deleteUser(viewModel.filteredUsers[index])
                    }
                }
            }
        }
    }
}
```

## iOS 14-16 with ObservableObject

For backward compatibility:

### ViewModel

```swift
import Combine

final class UserViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var users: [User] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published var searchText = ""
    
    var filteredUsers: [User] {
        guard !searchText.isEmpty else { return users }
        return users.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Dependencies
    private let userService: UserServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
    }
    
    // MARK: - Actions
    @MainActor
    func loadUsers() async {
        isLoading = true
        error = nil
        
        do {
            users = try await userService.fetchUsers()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
}
```

### View

```swift
struct UserListView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        NavigationView {
            // ... same content
        }
        .task {
            await viewModel.loadUsers()
        }
    }
}
```

**Key difference**: Use `@StateObject` (not `@State`) for `ObservableObject` types.

## Dependency Injection

### Using Environment

```swift
// Define environment key
private struct UserServiceKey: EnvironmentKey {
    static let defaultValue: UserServiceProtocol = UserService()
}

extension EnvironmentValues {
    var userService: UserServiceProtocol {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}

// Inject at app level
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.userService, UserService())
        }
    }
}

// Use in ViewModel
struct UserListView: View {
    @Environment(\.userService) private var userService
    @State private var viewModel: UserViewModel?
    
    var body: some View {
        // ...
    }
    .onAppear {
        viewModel = UserViewModel(userService: userService)
    }
}
```

### Using Factory Pattern

```swift
@Observable
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    lazy var userService: UserServiceProtocol = UserService()
    lazy var authService: AuthServiceProtocol = AuthService()
    
    // For testing
    func reset() {
        // Reset dependencies
    }
}
```

## Testing ViewModels

### Mock Service

```swift
final class MockUserService: UserServiceProtocol {
    var usersToReturn: [User] = []
    var errorToThrow: Error?
    var fetchUsersCalled = false
    
    func fetchUsers() async throws -> [User] {
        fetchUsersCalled = true
        if let error = errorToThrow { throw error }
        return usersToReturn
    }
}
```

### ViewModel Tests

```swift
import XCTest
@testable import MyApp

final class UserViewModelTests: XCTestCase {
    var sut: UserViewModel!
    var mockService: MockUserService!
    
    override func setUp() {
        mockService = MockUserService()
        sut = UserViewModel(userService: mockService)
    }
    
    func testLoadUsersSuccess() async {
        // Given
        let expectedUsers = [User(id: UUID(), name: "Test", email: "test@example.com")]
        mockService.usersToReturn = expectedUsers
        
        // When
        await sut.loadUsers()
        
        // Then
        XCTAssertTrue(mockService.fetchUsersCalled)
        XCTAssertEqual(sut.users.count, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.error)
    }
    
    func testLoadUsersFailure() async {
        // Given
        mockService.errorToThrow = URLError(.notConnectedToInternet)
        
        // When
        await sut.loadUsers()
        
        // Then
        XCTAssertTrue(sut.users.isEmpty)
        XCTAssertNotNil(sut.error)
    }
    
    func testFilteredUsers() async {
        // Given
        mockService.usersToReturn = [
            User(id: UUID(), name: "Alice", email: "alice@example.com"),
            User(id: UUID(), name: "Bob", email: "bob@example.com")
        ]
        await sut.loadUsers()
        
        // When
        sut.searchText = "Ali"
        
        // Then
        XCTAssertEqual(sut.filteredUsers.count, 1)
        XCTAssertEqual(sut.filteredUsers.first?.name, "Alice")
    }
}
```

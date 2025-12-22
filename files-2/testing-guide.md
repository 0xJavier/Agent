# SwiftUI Testing Guide

## Swift Testing Framework (iOS 18+ / Xcode 16+)

Modern approach using the new Swift Testing framework.

### Unit Tests

```swift
import Testing
@testable import MyApp

@Suite("Task ViewModel Tests")
struct TaskViewModelTests {
    
    @Test("Loading tasks updates state correctly")
    func loadTasks() async {
        // Arrange
        let mockService = MockTaskService()
        mockService.mockTasks = [Task(id: UUID(), title: "Test")]
        let viewModel = TaskViewModel(service: mockService)
        
        // Act
        await viewModel.loadTasks()
        
        // Assert
        #expect(viewModel.tasks.count == 1)
        #expect(viewModel.tasks.first?.title == "Test")
        #expect(viewModel.isLoading == false)
    }
    
    @Test("Error handling sets error state")
    func loadTasksError() async {
        let mockService = MockTaskService()
        mockService.shouldFail = true
        let viewModel = TaskViewModel(service: mockService)
        
        await viewModel.loadTasks()
        
        #expect(viewModel.error != nil)
        #expect(viewModel.tasks.isEmpty)
    }
    
    @Test("Toggle completion updates task", arguments: [true, false])
    func toggleCompletion(initialState: Bool) {
        var task = Task(id: UUID(), title: "Test", isCompleted: initialState)
        let viewModel = TaskViewModel()
        
        viewModel.toggleComplete(&task)
        
        #expect(task.isCompleted == !initialState)
    }
}
```

### Parameterized Tests

```swift
@Test("Price formatting", arguments: [
    (100, "$1.00"),
    (1050, "$10.50"),
    (0, "$0.00"),
    (99999, "$999.99")
])
func priceFormatting(cents: Int, expected: String) {
    let formatted = PriceFormatter.format(cents: cents)
    #expect(formatted == expected)
}
```

### Async Tests

```swift
@Test("Network request completes within timeout")
func networkTimeout() async throws {
    let service = NetworkService()
    
    try await confirmation(expectedCount: 1) { confirm in
        Task {
            _ = try await service.fetchData()
            confirm()
        }
    }
}
```

## XCTest (Pre-iOS 18)

```swift
import XCTest
@testable import MyApp

final class TaskViewModelTests: XCTestCase {
    var viewModel: TaskViewModel!
    var mockService: MockTaskService!
    
    override func setUp() {
        super.setUp()
        mockService = MockTaskService()
        viewModel = TaskViewModel(service: mockService)
    }
    
    func testLoadTasks() async {
        mockService.mockTasks = [Task(id: UUID(), title: "Test")]
        
        await viewModel.loadTasks()
        
        XCTAssertEqual(viewModel.tasks.count, 1)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

## UI Testing

```swift
import XCTest

final class TaskListUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    func testAddNewTask() {
        // Tap add button
        app.buttons["Add Task"].tap()
        
        // Fill in form
        let titleField = app.textFields["Task Title"]
        titleField.tap()
        titleField.typeText("New Task")
        
        // Save
        app.buttons["Save"].tap()
        
        // Verify task appears in list
        XCTAssertTrue(app.staticTexts["New Task"].exists)
    }
    
    func testSwipeToDelete() {
        let taskCell = app.cells.containing(.staticText, identifier: "Test Task").firstMatch
        
        taskCell.swipeLeft()
        app.buttons["Delete"].tap()
        
        XCTAssertFalse(app.staticTexts["Test Task"].exists)
    }
}
```

### Accessibility Identifiers

```swift
// In your view
Button("Add Task") { }
    .accessibilityIdentifier("Add Task")

TextField("Title", text: $title)
    .accessibilityIdentifier("Task Title")
```

## Snapshot Testing

Using swift-snapshot-testing:

```swift
import SnapshotTesting
import SwiftUI
import XCTest

final class TaskRowSnapshotTests: XCTestCase {
    func testTaskRowAppearance() {
        let task = Task(id: UUID(), title: "Test Task", isCompleted: false)
        let view = TaskRow(task: task)
            .frame(width: 375)
        
        assertSnapshot(of: view, as: .image)
    }
    
    func testTaskRowCompleted() {
        let task = Task(id: UUID(), title: "Done Task", isCompleted: true)
        let view = TaskRow(task: task)
            .frame(width: 375)
        
        assertSnapshot(of: view, as: .image)
    }
    
    func testTaskRowDarkMode() {
        let task = Task(id: UUID(), title: "Dark Task", isCompleted: false)
        let view = TaskRow(task: task)
            .frame(width: 375)
            .environment(\.colorScheme, .dark)
        
        assertSnapshot(of: view, as: .image)
    }
}
```

## Preview Testing

Use previews as living documentation and quick visual tests:

```swift
#Preview("Default State") {
    TaskListView(viewModel: .preview)
}

#Preview("Loading") {
    TaskListView(viewModel: .loading)
}

#Preview("Empty State") {
    TaskListView(viewModel: .empty)
}

#Preview("Error State") {
    TaskListView(viewModel: .error)
}

// Preview helpers
extension TaskViewModel {
    static var preview: TaskViewModel {
        let vm = TaskViewModel(service: MockTaskService.preview)
        vm.tasks = Task.samples
        return vm
    }
    
    static var loading: TaskViewModel {
        let vm = TaskViewModel()
        vm.isLoading = true
        return vm
    }
}
```

## Mock Creation Patterns

```swift
final class MockTaskService: TaskServiceProtocol, @unchecked Sendable {
    var mockTasks: [Task] = []
    var shouldFail = false
    var fetchCallCount = 0
    
    func fetchTasks() async throws -> [Task] {
        fetchCallCount += 1
        if shouldFail {
            throw MockError.intentionalFailure
        }
        return mockTasks
    }
}

enum MockError: Error {
    case intentionalFailure
}
```

## Test Organization

```
Tests/
├── UnitTests/
│   ├── ViewModels/
│   │   ├── TaskViewModelTests.swift
│   │   └── UserViewModelTests.swift
│   ├── Services/
│   │   └── NetworkServiceTests.swift
│   └── Helpers/
│       └── DateFormatterTests.swift
├── IntegrationTests/
│   └── TaskFlowTests.swift
├── UITests/
│   ├── TaskListUITests.swift
│   └── OnboardingUITests.swift
└── SnapshotTests/
    └── ComponentSnapshotTests.swift
```

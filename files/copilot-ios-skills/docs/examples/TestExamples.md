# Test Examples

> **Add your code examples here.** Copilot will reference these when generating tests.

## Your Test Class Template

```swift
// TODO: Add your test class template
import XCTest
@testable import YourApp

final class ExampleTests: XCTestCase {
    private var sut: Example!
    private var mockDependency: MockDependency!
    
    override func setUp() {
        super.setUp()
        // Your setup pattern
    }
    
    override func tearDown() {
        // Your teardown pattern
        super.tearDown()
    }
}
```

## Your Test Naming Convention

```swift
// TODO: Show your naming pattern
func test_methodName_whenCondition_thenExpectedResult() {
    // Arrange
    
    // Act
    
    // Assert
}
```

## Your Mock Patterns

```swift
// TODO: Add your mock creation pattern
final class MockService: ServiceProtocol {
    // Your mock pattern
}
```

## Your Test Data Patterns

```swift
// TODO: Add your mock data extensions
extension User {
    static let mock = User(/* your pattern */)
}
```

## Your Async Test Patterns

```swift
// TODO: Show how you test async code
func test_asyncMethod_succeeds() async throws {
    // Your async testing pattern
}
```

## Your Common Assertions

```swift
// TODO: Show any custom assertion helpers you use
```

---

## Instructions

Add your real test patterns here. Copilot will generate tests matching your testing style.

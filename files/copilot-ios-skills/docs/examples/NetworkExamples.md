# Network Examples

> **Add your code examples here.** Copilot will reference these when generating network code.

## Your Endpoint Pattern

```swift
// TODO: Add your endpoint enum pattern
enum ExampleEndpoint: Endpoint {
    case list
    case get(id: String)
    
    var path: String {
        // Your path pattern
    }
    
    var method: HTTPMethod {
        // Your method pattern
    }
}
```

## Your Service Pattern

```swift
// TODO: Add your service pattern
protocol ExampleServiceProtocol: Sendable {
    func fetchItems() async throws -> [Item]
}

final class ExampleService: ExampleServiceProtocol, Sendable {
    private let client: NetworkClientProtocol
    
    // Your implementation
}
```

## Your Request/Response Models

```swift
// TODO: Add your DTO patterns
struct ExampleRequest: Encodable {
    // Your request pattern
}

struct ExampleResponse: Decodable {
    // Your response pattern
}
```

## Your Mock Pattern

```swift
// TODO: Add your mock service pattern
final class MockExampleService: ExampleServiceProtocol {
    var result: Result<[Item], Error> = .success([])
    
    // Your mock pattern
}
```

## Your Error Types

```swift
// TODO: Add your network error enum
enum NetworkError: LocalizedError {
    // Your error cases
}
```

## Your Client Configuration

```swift
// TODO: Show your NetworkClient setup, interceptors, etc.
```

---

## Instructions

Add your actual networking code patterns here. Copilot will generate network code matching your style.

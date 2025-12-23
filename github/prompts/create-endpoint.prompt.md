---
mode: 'agent'
description: 'Create a new API endpoint with request/response models and repository method'
---

Create a new API endpoint following our networking patterns.

## Endpoint Details

- **Resource name**: ${input:resource:Resource name (e.g., Product, User, Order)}
- **Operations needed**: ${input:operations:Which operations? (list, detail, create, update, delete)}
- **Base path**: ${input:basePath:API path (e.g., /products, /users)}

## Our Networking Pattern

### 1. Endpoint Definition

Create in `Core/Networking/Endpoints/${resource}Endpoints.swift`:

```swift
enum ${resource}Endpoint: Endpoint {
    case list(page: Int, limit: Int)
    case detail(id: String)
    case create(Create${resource}Request)
    case update(id: String, Update${resource}Request)
    case delete(id: String)
    
    var path: String {
        switch self {
        case .list, .create:
            return "${basePath}"
        case .detail(let id), .update(let id, _), .delete(let id):
            return "${basePath}/\(id)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .list, .detail: return .get
        case .create: return .post
        case .update: return .put
        case .delete: return .delete
        }
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .list(let page, let limit):
            return [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ]
        default:
            return nil
        }
    }
    
    var body: Encodable? {
        switch self {
        case .create(let request): return request
        case .update(_, let request): return request
        default: return nil
        }
    }
}
```

### 2. Request/Response Models

Create in `Core/Networking/Models/`:

```swift
// Request models (Encodable)
struct Create${resource}Request: Encodable {
    let name: String
    // Add fields...
}

// Response models (Decodable)
struct ${resource}Response: Decodable {
    let id: String
    let name: String
    let createdAt: Date
    // Add fields...
}

struct ${resource}ListResponse: Decodable {
    let items: [${resource}Response]
    let totalCount: Int
    let page: Int
    let hasMore: Bool
}
```

### 3. Repository

Create in `Features/${resource}/${resource}Repository.swift`:

```swift
final class ${resource}Repository {
    static let shared = ${resource}Repository()
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    func fetch${resource}s(page: Int = 1) async throws -> ${resource}ListResponse {
        try await apiClient.request(${resource}Endpoint.list(page: page, limit: 20))
    }
    
    func fetch${resource}(id: String) async throws -> ${resource}Response {
        try await apiClient.request(${resource}Endpoint.detail(id: id))
    }
    
    func create${resource}(_ request: Create${resource}Request) async throws -> ${resource}Response {
        try await apiClient.request(${resource}Endpoint.create(request))
    }
    
    func delete${resource}(id: String) async throws {
        try await apiClient.requestVoid(${resource}Endpoint.delete(id: id))
    }
}
```

## Conventions

- Use `snake_case` for JSON keys (handled by encoder/decoder)
- Response models should be `Decodable`
- Request models should be `Encodable`
- Repository methods should be `async throws`
- Include error tracking in ViewModel when calling repository

## Please Generate

1. Endpoint enum with the specified operations
2. Request model(s) if create/update operations
3. Response model(s)
4. Repository with methods for each operation

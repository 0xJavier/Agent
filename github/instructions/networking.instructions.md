---
applyTo: "**/Networking/**/*.swift,**/Core/API/**/*.swift,**/*Endpoint*.swift,**/*Repository*.swift"
description: "Networking layer patterns using URLSession and async/await"
---

# Networking Implementation

## Architecture

```
Core/Networking/
├── APIClient.swift         # Main client
├── Endpoint.swift          # Endpoint protocol
├── APIError.swift          # Error types
├── Endpoints/              # Endpoint definitions
└── Models/                 # Response models
```

## Adding a New Endpoint

### Step 1: Define the Endpoint

```swift
enum ProductEndpoint: Endpoint {
    case list(page: Int, limit: Int)
    case detail(id: String)
    case create(CreateProductRequest)
    case delete(id: String)
    
    var path: String {
        switch self {
        case .list: return "/products"
        case .detail(let id), .delete(let id): return "/products/\(id)"
        case .create: return "/products"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .list, .detail: return .get
        case .create: return .post
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
        default: return nil
        }
    }
    
    var body: Encodable? {
        switch self {
        case .create(let request): return request
        default: return nil
        }
    }
}
```

### Step 2: Define Models

```swift
// Request
struct CreateProductRequest: Encodable {
    let name: String
    let price: Decimal
    let categoryId: String
}

// Response
struct ProductResponse: Decodable {
    let id: String
    let name: String
    let price: Decimal
    let createdAt: Date
}
```

### Step 3: Add Repository Method

```swift
final class ProductRepository {
    private let apiClient: APIClient
    
    func fetchProducts(page: Int = 1) async throws -> [ProductResponse] {
        try await apiClient.request(ProductEndpoint.list(page: page, limit: 20))
    }
    
    func createProduct(_ request: CreateProductRequest) async throws -> ProductResponse {
        try await apiClient.request(ProductEndpoint.create(request))
    }
}
```

## Endpoint Protocol

```swift
protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Encodable? { get }
}

extension Endpoint {
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Encodable? { nil }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}
```

## Error Handling

```swift
enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case notFound
    case validationError([ValidationError])
    case serverError(Int)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Please sign in to continue"
        case .notFound: return "Resource not found"
        case .serverError: return "Server error. Please try again."
        case .networkError: return "Network connection error"
        default: return "An error occurred"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .serverError, .networkError: return true
        default: return false
        }
    }
}
```

## ViewModel Usage

```swift
@MainActor
final class ProductListViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var error: APIError?
    
    func loadProducts() async {
        do {
            let response = try await repository.fetchProducts()
            products = response.map(Product.init)
        } catch let apiError as APIError {
            error = apiError
            Analytics.shared.track(.errorOccurred(
                type: "api",
                message: apiError.localizedDescription,
                screen: "ProductList"
            ))
        } catch {
            self.error = .networkError(error)
        }
    }
}
```

## Checklist

- [ ] Create endpoint case in `*Endpoints.swift`
- [ ] Define request model (if POST/PUT/PATCH)
- [ ] Define response model conforming to `Decodable`
- [ ] Add repository method
- [ ] Use `snake_case` for JSON (handled by decoder)
- [ ] Handle all error cases
- [ ] Track errors with analytics

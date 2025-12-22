---
name: networking
description: iOS networking layer implementation using URLSession and async/await. Use this skill when adding new API endpoints, creating network requests, handling API responses, implementing error handling for network calls, or working with the APIClient. Covers endpoint definition, request building, response parsing, and error handling patterns.
---

# Networking Implementation

## Architecture Overview

```
Core/Networking/
├── APIClient.swift         # Main client, executes requests
├── Endpoint.swift          # Protocol for defining endpoints
├── APIError.swift          # Typed error handling
├── Endpoints/              # Endpoint definitions by feature
│   ├── UserEndpoints.swift
│   └── ProductEndpoints.swift
└── Models/                 # Response models (Codable)
```

## Adding a New Endpoint

### Step 1: Define the Endpoint

```swift
// In Endpoints/ProductEndpoints.swift

enum ProductEndpoint: Endpoint {
    case list(page: Int, limit: Int)
    case detail(id: String)
    case create(CreateProductRequest)
    case update(id: String, UpdateProductRequest)
    case delete(id: String)
    
    var path: String {
        switch self {
        case .list:
            return "/products"
        case .detail(let id), .update(let id, _), .delete(let id):
            return "/products/\(id)"
        case .create:
            return "/products"
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
        case .create(let request):
            return request
        case .update(_, let request):
            return request
        default:
            return nil
        }
    }
}
```

### Step 2: Define Request/Response Models

```swift
// Request model
struct CreateProductRequest: Encodable {
    let name: String
    let price: Decimal
    let categoryId: String
}

// Response model
struct ProductResponse: Decodable {
    let id: String
    let name: String
    let price: Decimal
    let category: CategoryResponse
    let createdAt: Date
}

struct ProductListResponse: Decodable {
    let items: [ProductResponse]
    let totalCount: Int
    let page: Int
    let hasMore: Bool
}
```

### Step 3: Add Repository Method

```swift
// In Features/Products/ProductRepository.swift

final class ProductRepository {
    static let shared = ProductRepository()
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    func fetchProducts(page: Int = 1, limit: Int = 20) async throws -> ProductListResponse {
        try await apiClient.request(ProductEndpoint.list(page: page, limit: limit))
    }
    
    func fetchProduct(id: String) async throws -> ProductResponse {
        try await apiClient.request(ProductEndpoint.detail(id: id))
    }
    
    func createProduct(_ request: CreateProductRequest) async throws -> ProductResponse {
        try await apiClient.request(ProductEndpoint.create(request))
    }
    
    func deleteProduct(id: String) async throws {
        try await apiClient.requestVoid(ProductEndpoint.delete(id: id))
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

// Default implementations
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

## APIClient Implementation

```swift
final class APIClient: Sendable {
    static let shared = APIClient()
    
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(
        baseURL: URL = Configuration.apiBaseURL,
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
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }
    
    func requestVoid(_ endpoint: Endpoint) async throws {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response, data: data)
    }
    
    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)!
        components.queryItems = endpoint.queryItems
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add auth token if available
        if let token = AuthManager.shared.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Encode body
        if let body = endpoint.body {
            request.httpBody = try encoder.encode(body)
        }
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 422:
            let validationError = try? decoder.decode(ValidationErrorResponse.self, from: data)
            throw APIError.validationError(validationError?.errors ?? [])
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode)
        default:
            throw APIError.httpError(httpResponse.statusCode)
        }
    }
}
```

## Error Handling

```swift
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case validationError([ValidationError])
    case serverError(Int)
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Please sign in to continue"
        case .forbidden:
            return "You don't have permission to access this"
        case .notFound:
            return "The requested resource was not found"
        case .validationError(let errors):
            return errors.first?.message ?? "Validation failed"
        case .serverError:
            return "Server error. Please try again later."
        case .httpError(let code):
            return "Request failed with status \(code)"
        case .decodingError:
            return "Failed to process server response"
        case .networkError:
            return "Network connection error"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .serverError, .networkError:
            return true
        default:
            return false
        }
    }
}

struct ValidationError: Decodable {
    let field: String
    let message: String
}

struct ValidationErrorResponse: Decodable {
    let errors: [ValidationError]
}
```

## Usage in ViewModels

```swift
@MainActor
final class ProductListViewModel: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var error: APIError?
    @Published private(set) var isLoading = false
    
    private let repository: ProductRepository
    
    init(repository: ProductRepository = .shared) {
        self.repository = repository
    }
    
    func loadProducts() async {
        isLoading = true
        error = nil
        
        do {
            let response = try await repository.fetchProducts()
            products = response.items.map(Product.init)
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
        
        isLoading = false
    }
}
```

## Checklist for New Endpoints

1. [ ] Create endpoint case in appropriate `*Endpoints.swift` file
2. [ ] Define request model (if POST/PUT/PATCH) conforming to `Encodable`
3. [ ] Define response model conforming to `Decodable`
4. [ ] Add repository method with proper error handling
5. [ ] Use `snake_case` for JSON keys (handled by encoder/decoder)
6. [ ] Handle all relevant error cases
7. [ ] Add analytics tracking for errors

## See Also

- Example implementation: [examples/NetworkingExample.swift](examples/NetworkingExample.swift)

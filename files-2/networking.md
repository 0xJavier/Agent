# Networking in SwiftUI

## Table of Contents

1. [Basic URLSession](#basic-urlsession)
2. [API Client Pattern](#api-client-pattern)
3. [Error Handling](#error-handling)
4. [Loading States](#loading-states-in-views)
5. [Image Loading](#image-loading)
6. [Caching Strategies](#caching-strategies)

## Basic URLSession

### Simple GET Request

```swift
func fetchData<T: Decodable>(from url: URL) async throws -> T {
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.invalidResponse
    }
    
    return try JSONDecoder().decode(T.self, from: data)
}
```

### POST Request with Body

```swift
func post<T: Encodable, R: Decodable>(
    to url: URL,
    body: T
) async throws -> R {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(body)
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        throw NetworkError.invalidResponse
    }
    
    return try JSONDecoder().decode(R.self, from: data)
}
```

## API Client Pattern

### Protocol-Based Design

```swift
protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

struct Endpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryItems: [URLQueryItem]?
    let body: Data?
    
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }
}
```

### Implementation

```swift
final class APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(for: endpoint)
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response)
        return try decoder.decode(T.self, from: data)
    }
    
    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: true)
        components?.queryItems = endpoint.queryItems
        
        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        
        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299: return
        case 401: throw NetworkError.unauthorized
        case 404: throw NetworkError.notFound
        case 500...599: throw NetworkError.serverError(httpResponse.statusCode)
        default: throw NetworkError.unknown(httpResponse.statusCode)
        }
    }
}
```

### Endpoint Builder

```swift
enum UsersEndpoint {
    case list
    case detail(id: UUID)
    case create(User)
    case update(User)
    case delete(id: UUID)
    
    var endpoint: Endpoint {
        switch self {
        case .list:
            return Endpoint(path: "/users", method: .get, headers: [:], queryItems: nil, body: nil)
        case .detail(let id):
            return Endpoint(path: "/users/\(id)", method: .get, headers: [:], queryItems: nil, body: nil)
        case .create(let user):
            return Endpoint(
                path: "/users",
                method: .post,
                headers: ["Content-Type": "application/json"],
                queryItems: nil,
                body: try? JSONEncoder().encode(user)
            )
        case .update(let user):
            return Endpoint(
                path: "/users/\(user.id)",
                method: .put,
                headers: ["Content-Type": "application/json"],
                queryItems: nil,
                body: try? JSONEncoder().encode(user)
            )
        case .delete(let id):
            return Endpoint(path: "/users/\(id)", method: .delete, headers: [:], queryItems: nil, body: nil)
        }
    }
}
```

## Error Handling

### Network Error Types

```swift
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case notFound
    case serverError(Int)
    case decodingError(Error)
    case noConnection
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .unauthorized: return "Please log in again"
        case .notFound: return "Resource not found"
        case .serverError(let code): return "Server error (\(code))"
        case .decodingError: return "Failed to process data"
        case .noConnection: return "No internet connection"
        case .unknown(let code): return "Unknown error (\(code))"
        }
    }
}
```

### Retry Logic

```swift
func requestWithRetry<T: Decodable>(
    _ endpoint: Endpoint,
    maxRetries: Int = 3,
    delay: TimeInterval = 1.0
) async throws -> T {
    var lastError: Error?
    
    for attempt in 0..<maxRetries {
        do {
            return try await request(endpoint)
        } catch {
            lastError = error
            
            // Don't retry for client errors
            if case NetworkError.unauthorized = error { throw error }
            if case NetworkError.notFound = error { throw error }
            
            if attempt < maxRetries - 1 {
                try await Task.sleep(nanoseconds: UInt64(delay * Double(attempt + 1) * 1_000_000_000))
            }
        }
    }
    
    throw lastError ?? NetworkError.unknown(0)
}
```

## Loading States in Views

### State Enum

```swift
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }
    
    var error: Error? {
        if case .error(let error) = self { return error }
        return nil
    }
}
```

### View Implementation

```swift
struct UsersView: View {
    @State private var state: LoadingState<[User]> = .idle
    private let apiClient: APIClientProtocol
    
    var body: some View {
        Group {
            switch state {
            case .idle:
                Color.clear.onAppear { Task { await load() } }
            case .loading:
                ProgressView()
            case .loaded(let users):
                UserList(users: users)
            case .error(let error):
                ErrorView(error: error) { Task { await load() } }
            }
        }
    }
    
    private func load() async {
        state = .loading
        do {
            let users: [User] = try await apiClient.request(UsersEndpoint.list.endpoint)
            state = .loaded(users)
        } catch {
            state = .error(error)
        }
    }
}
```

## Image Loading

### AsyncImage (iOS 15+)

```swift
AsyncImage(url: user.avatarURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    case .failure:
        Image(systemName: "person.circle.fill")
            .foregroundStyle(.secondary)
    @unknown default:
        EmptyView()
    }
}
.frame(width: 50, height: 50)
.clipShape(Circle())
```

### Custom Cached Image Loader

```swift
actor ImageCache {
    static let shared = ImageCache()
    private var cache: [URL: UIImage] = [:]
    
    func image(for url: URL) -> UIImage? {
        cache[url]
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        cache[url] = image
    }
}

@Observable
final class CachedImageLoader {
    var image: UIImage?
    var isLoading = false
    
    func load(from url: URL) async {
        if let cached = await ImageCache.shared.image(for: url) {
            image = cached
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                await ImageCache.shared.setImage(uiImage, for: url)
                image = uiImage
            }
        } catch {
            // Handle error
        }
    }
}
```

## Caching Strategies

### URLCache Configuration

```swift
let cache = URLCache(
    memoryCapacity: 50 * 1024 * 1024,  // 50 MB
    diskCapacity: 100 * 1024 * 1024     // 100 MB
)

let configuration = URLSessionConfiguration.default
configuration.urlCache = cache
configuration.requestCachePolicy = .returnCacheDataElseLoad

let session = URLSession(configuration: configuration)
```

### Custom Cache with Expiration

```swift
actor DataCache<T: Codable> {
    private struct CacheEntry {
        let value: T
        let timestamp: Date
    }
    
    private var cache: [String: CacheEntry] = [:]
    private let expiration: TimeInterval
    
    init(expiration: TimeInterval = 300) { // 5 minutes default
        self.expiration = expiration
    }
    
    func get(_ key: String) -> T? {
        guard let entry = cache[key] else { return nil }
        
        if Date().timeIntervalSince(entry.timestamp) > expiration {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.value
    }
    
    func set(_ value: T, for key: String) {
        cache[key] = CacheEntry(value: value, timestamp: Date())
    }
    
    func clear() {
        cache.removeAll()
    }
}
```

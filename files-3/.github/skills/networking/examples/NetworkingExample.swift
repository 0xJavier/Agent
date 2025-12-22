import Foundation

// MARK: - Endpoint Protocol

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

// MARK: - API Error

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

// MARK: - API Client

final class APIClient: Sendable {
    static let shared = APIClient()
    
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init(
        baseURL: URL = URL(string: "https://api.example.com")!,
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
    
    /// Execute a request and decode the response
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try buildRequest(for: endpoint)
        
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, data: data)
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    /// Execute a request without expecting a response body
    func requestVoid(_ endpoint: Endpoint) async throws {
        let request = try buildRequest(for: endpoint)
        
        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response, data: data)
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }
    
    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        )!
        
        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add auth token if available
        // if let token = AuthManager.shared.accessToken {
        //     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // }
        
        // Add custom headers
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Encode body
        if let body = endpoint.body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
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
            // Optionally trigger re-authentication
            // NotificationCenter.default.post(name: .userSessionExpired, object: nil)
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

// Type-erased Encodable wrapper
private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    
    init(_ value: Encodable) {
        self.encode = value.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

// MARK: - Example Endpoints

enum UserEndpoint: Endpoint {
    case me
    case profile(userId: String)
    case updateProfile(UpdateProfileRequest)
    case uploadAvatar(Data)
    
    var path: String {
        switch self {
        case .me:
            return "/users/me"
        case .profile(let userId):
            return "/users/\(userId)"
        case .updateProfile:
            return "/users/me"
        case .uploadAvatar:
            return "/users/me/avatar"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .me, .profile:
            return .get
        case .updateProfile:
            return .patch
        case .uploadAvatar:
            return .post
        }
    }
    
    var body: Encodable? {
        switch self {
        case .updateProfile(let request):
            return request
        default:
            return nil
        }
    }
}

// MARK: - Request/Response Models

struct UpdateProfileRequest: Encodable {
    let displayName: String?
    let bio: String?
    let location: String?
}

struct UserResponse: Decodable {
    let id: String
    let email: String
    let displayName: String
    let bio: String?
    let avatarUrl: URL?
    let createdAt: Date
}

// MARK: - Repository Example

final class UserRepository {
    static let shared = UserRepository()
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }
    
    func fetchCurrentUser() async throws -> UserResponse {
        try await apiClient.request(UserEndpoint.me)
    }
    
    func fetchUser(id: String) async throws -> UserResponse {
        try await apiClient.request(UserEndpoint.profile(userId: id))
    }
    
    func updateProfile(displayName: String? = nil, bio: String? = nil) async throws -> UserResponse {
        let request = UpdateProfileRequest(displayName: displayName, bio: bio, location: nil)
        return try await apiClient.request(UserEndpoint.updateProfile(request))
    }
}

// MARK: - ViewModel Usage Example

import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: UserResponse?
    @Published private(set) var error: APIError?
    @Published private(set) var isLoading = false
    @Published private(set) var isSaving = false
    
    private let repository: UserRepository
    
    init(repository: UserRepository = .shared) {
        self.repository = repository
    }
    
    func loadProfile() async {
        isLoading = true
        error = nil
        
        do {
            user = try await repository.fetchCurrentUser()
        } catch let apiError as APIError {
            error = apiError
            // Track error
            Analytics.shared.track(.errorOccurred(
                type: "api",
                message: apiError.localizedDescription,
                screen: "Profile"
            ))
        } catch {
            self.error = .networkError(error)
        }
        
        isLoading = false
    }
    
    func updateProfile(displayName: String, bio: String) async -> Bool {
        isSaving = true
        error = nil
        
        do {
            user = try await repository.updateProfile(displayName: displayName, bio: bio)
            isSaving = false
            return true
        } catch let apiError as APIError {
            error = apiError
            isSaving = false
            return false
        } catch {
            self.error = .networkError(error)
            isSaving = false
            return false
        }
    }
}

// MARK: - Retry Logic Example

extension APIClient {
    /// Execute a request with automatic retry for retryable errors
    func requestWithRetry<T: Decodable>(
        _ endpoint: Endpoint,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await request(endpoint)
            } catch let error as APIError where error.isRetryable {
                lastError = error
                if attempt < maxRetries - 1 {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                }
            } catch {
                throw error
            }
        }
        
        throw lastError ?? APIError.networkError(NSError(domain: "Unknown", code: -1))
    }
}

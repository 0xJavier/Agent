import SwiftUI

// MARK: - Analytics Core

/// Centralized analytics tracking
final class Analytics: Sendable {
    static let shared = Analytics()
    
    private init() {}
    
    func track(_ event: AnalyticsEvent) {
        // Replace with your analytics provider
        // e.g., Firebase.Analytics.logEvent(event.name, parameters: event.parameters)
        #if DEBUG
        print("📊 Analytics: \(event.name) - \(event.parameters)")
        #endif
    }
}

// MARK: - Event Definitions

enum AnalyticsEvent {
    // Screen lifecycle
    case screenViewed(name: String)
    
    // User interactions
    case buttonTapped(name: String, screen: String)
    case featureUsed(name: String, metadata: [String: Any]?)
    
    // Errors
    case errorOccurred(type: String, message: String, screen: String)
    
    // Conversions
    case purchaseCompleted(productId: String, amount: Decimal)
    case signUpCompleted(method: String)
    
    var name: String {
        switch self {
        case .screenViewed: return "screen_viewed"
        case .buttonTapped: return "button_tapped"
        case .featureUsed: return "feature_used"
        case .errorOccurred: return "error_occurred"
        case .purchaseCompleted: return "purchase_completed"
        case .signUpCompleted: return "sign_up_completed"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .screenViewed(let name):
            return ["screen_name": name]
            
        case .buttonTapped(let name, let screen):
            return [
                "button_name": name,
                "screen_name": screen
            ]
            
        case .featureUsed(let name, let metadata):
            var params: [String: Any] = ["feature_name": name]
            if let metadata {
                params.merge(metadata) { _, new in new }
            }
            return params
            
        case .errorOccurred(let type, let message, let screen):
            return [
                "error_type": type,
                "error_message": message,
                "screen_name": screen
            ]
            
        case .purchaseCompleted(let productId, let amount):
            return [
                "product_id": productId,
                "amount": NSDecimalNumber(decimal: amount).doubleValue
            ]
            
        case .signUpCompleted(let method):
            return ["sign_up_method": method]
        }
    }
}

// MARK: - SwiftUI View Modifier

struct AnalyticsScreenModifier: ViewModifier {
    let screenName: String
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                Analytics.shared.track(.screenViewed(name: screenName))
            }
    }
}

extension View {
    /// Tracks screen view when this view appears
    func trackScreen(_ name: String) -> some View {
        modifier(AnalyticsScreenModifier(screenName: name))
    }
}

// MARK: - Tracked Button Component

/// A button that automatically tracks taps
struct TrackedButton<Label: View>: View {
    let screen: String
    let eventName: String
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    
    init(
        _ eventName: String,
        screen: String,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.eventName = eventName
        self.screen = screen
        self.action = action
        self.label = label
    }
    
    var body: some View {
        Button {
            Analytics.shared.track(.buttonTapped(name: eventName, screen: screen))
            action()
        } label: {
            label()
        }
    }
}

// Convenience initializer for text buttons
extension TrackedButton where Label == Text {
    init(
        _ title: String,
        screen: String,
        action: @escaping () -> Void
    ) {
        self.eventName = title
        self.screen = screen
        self.action = action
        self.label = { Text(title) }
    }
}

// MARK: - Example Usage

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome, \(viewModel.userName)")
                .font(.title)
            
            TrackedButton("Edit Profile", screen: "Profile") {
                viewModel.didTapEditProfile()
            }
            
            TrackedButton("Settings", screen: "Profile") {
                viewModel.didTapSettings()
            }
            
            TrackedButton("sign_out", screen: "Profile") {
                viewModel.didTapSignOut()
            } label: {
                Text("Sign Out")
                    .foregroundColor(.red)
            }
        }
        .trackScreen("Profile")
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var userName: String = "User"
    
    func didTapEditProfile() {
        // Analytics already tracked by TrackedButton
        // Add business logic here
    }
    
    func didTapSettings() {
        // Navigate to settings
    }
    
    func didTapSignOut() {
        Analytics.shared.track(.featureUsed(name: "sign_out", metadata: nil))
        // Sign out logic
    }
}

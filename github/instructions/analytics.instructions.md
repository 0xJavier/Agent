---
applyTo: "**/Analytics/**/*.swift,**/Features/**/*.swift"
description: "Analytics event tracking patterns and conventions"
---

# Analytics Implementation

## Quick Start

Track events using the shared `Analytics` instance:

```swift
Analytics.shared.track(.screenViewed(name: "Home"))
Analytics.shared.track(.buttonTapped(name: "SignUp", screen: "Onboarding"))
```

## Event Definition Pattern

All events are defined in the `AnalyticsEvent` enum:

```swift
enum AnalyticsEvent {
    case screenViewed(name: String)
    case buttonTapped(name: String, screen: String)
    case featureUsed(name: String, metadata: [String: Any]?)
    case errorOccurred(type: String, message: String, screen: String)
    case purchaseCompleted(productId: String, amount: Decimal)
    
    var name: String {
        switch self {
        case .screenViewed: return "screen_viewed"
        case .buttonTapped: return "button_tapped"
        case .featureUsed: return "feature_used"
        case .errorOccurred: return "error_occurred"
        case .purchaseCompleted: return "purchase_completed"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .screenViewed(let name):
            return ["screen_name": name]
        case .buttonTapped(let name, let screen):
            return ["button_name": name, "screen_name": screen]
        // ... other cases
        }
    }
}
```

## Naming Conventions

- Event names: `snake_case` (e.g., `button_tapped`, `screen_viewed`)
- Format: `[object]_[action]`
- Parameter keys: `snake_case` (e.g., `screen_name`, `button_name`)
- Always include `screen_name` for context

## SwiftUI Integration

### Screen Tracking

```swift
extension View {
    func trackScreen(_ name: String) -> some View {
        onAppear {
            Analytics.shared.track(.screenViewed(name: name))
        }
    }
}

// Usage
struct HomeView: View {
    var body: some View {
        VStack { /* content */ }
            .trackScreen("Home")
    }
}
```

### Button Tracking

```swift
struct TrackedButton<Label: View>: View {
    let screen: String
    let eventName: String
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    
    var body: some View {
        Button {
            Analytics.shared.track(.buttonTapped(name: eventName, screen: screen))
            action()
        } label: {
            label()
        }
    }
}
```

## ViewModel Integration

Track events in ViewModels for actions involving business logic:

```swift
@MainActor
final class ProfileViewModel: ObservableObject {
    func didTapEditProfile() {
        Analytics.shared.track(.buttonTapped(name: "EditProfile", screen: "Profile"))
        // Business logic...
    }
}
```

## Checklist for New Features

- [ ] Add screen view tracking with `.trackScreen("FeatureName")`
- [ ] Track primary user actions (button taps, gestures)
- [ ] Track conversion/completion events
- [ ] Track errors with context
- [ ] Add new event cases to `AnalyticsEvent` enum
- [ ] Include `screen_name` in all events

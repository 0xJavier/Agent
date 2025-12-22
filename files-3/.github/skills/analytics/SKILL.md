---
name: analytics
description: Analytics event tracking implementation for iOS. Use this skill when creating new features that need analytics, adding tracking to existing views, implementing user action tracking, or working with analytics events. Covers event naming, parameter conventions, and integration with the Analytics framework.
---

# Analytics Implementation

## Quick Start

Track events using the shared `Analytics` instance:

```swift
Analytics.shared.track(.screenViewed(name: "Home"))
Analytics.shared.track(.buttonTapped(name: "SignUp", screen: "Onboarding"))
```

## Event Definition Pattern

All events are defined in the `AnalyticsEvent` enum. Add new events here:

```swift
// In Core/Analytics/AnalyticsEvent.swift
enum AnalyticsEvent {
    // Screen events
    case screenViewed(name: String)
    
    // User actions
    case buttonTapped(name: String, screen: String)
    case featureUsed(name: String, metadata: [String: Any]?)
    
    // Conversion events
    case purchaseCompleted(productId: String, amount: Decimal)
    
    var name: String {
        switch self {
        case .screenViewed: return "screen_viewed"
        case .buttonTapped: return "button_tapped"
        case .featureUsed: return "feature_used"
        case .purchaseCompleted: return "purchase_completed"
        }
    }
    
    var parameters: [String: Any] {
        switch self {
        case .screenViewed(let name):
            return ["screen_name": name]
        case .buttonTapped(let name, let screen):
            return ["button_name": name, "screen_name": screen]
        case .featureUsed(let name, let metadata):
            var params: [String: Any] = ["feature_name": name]
            if let metadata { params.merge(metadata) { _, new in new } }
            return params
        case .purchaseCompleted(let productId, let amount):
            return ["product_id": productId, "amount": amount]
        }
    }
}
```

## Naming Conventions

### Event Names
- Use `snake_case` for event names
- Format: `[object]_[action]` (e.g., `button_tapped`, `screen_viewed`)
- Be specific but not overly long

### Parameter Names
- Use `snake_case` for parameter keys
- Common parameters: `screen_name`, `button_name`, `item_id`, `source`
- Always include `screen_name` for context

### Standard Events to Track

| User Action | Event |
|------------|-------|
| Screen appears | `screenViewed(name:)` |
| Button tap | `buttonTapped(name:screen:)` |
| Feature interaction | `featureUsed(name:metadata:)` |
| Error occurs | `errorOccurred(type:message:screen:)` |
| Purchase | `purchaseCompleted(productId:amount:)` |

## SwiftUI Integration

### Screen Tracking with ViewModifier

```swift
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
    func trackScreen(_ name: String) -> some View {
        modifier(AnalyticsScreenModifier(screenName: name))
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
struct TrackedButton: View {
    let title: String
    let screen: String
    let action: () -> Void
    
    var body: some View {
        Button(title) {
            Analytics.shared.track(.buttonTapped(name: title, screen: screen))
            action()
        }
    }
}
```

## ViewModel Integration

Track events in ViewModels, not Views, for actions involving business logic:

```swift
@MainActor
final class ProfileViewModel: ObservableObject {
    func didTapEditProfile() {
        Analytics.shared.track(.buttonTapped(name: "EditProfile", screen: "Profile"))
        // Business logic...
    }
    
    func didCompletePurchase(productId: String, amount: Decimal) {
        Analytics.shared.track(.purchaseCompleted(productId: productId, amount: amount))
        // Purchase logic...
    }
}
```

## Checklist for New Features

When adding analytics to a new feature:

1. [ ] Add screen view tracking with `.trackScreen("FeatureName")`
2. [ ] Track primary user actions (button taps, gestures)
3. [ ] Track conversion/completion events
4. [ ] Track errors with context
5. [ ] Add new event cases to `AnalyticsEvent` enum
6. [ ] Include `screen_name` in all events for context

## See Also

- Example implementation: [examples/AnalyticsExample.swift](examples/AnalyticsExample.swift)

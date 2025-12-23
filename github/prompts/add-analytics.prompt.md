---
mode: 'agent'
description: 'Add analytics tracking to an existing feature or view'
---

Add analytics tracking to the specified feature following our patterns.

## Target

- **Feature/View**: ${input:target:Which file or feature needs analytics?}
- **Key actions to track**: ${input:actions:What user actions should be tracked? (e.g., button taps, form submissions)}

## Our Analytics Pattern

### Event Definition (add to AnalyticsEvent.swift)

```swift
enum AnalyticsEvent {
    // Add new cases here
    case screenViewed(name: String)
    case buttonTapped(name: String, screen: String)
    case featureUsed(name: String, metadata: [String: Any]?)
    case errorOccurred(type: String, message: String, screen: String)
    
    var name: String {
        // Use snake_case: "button_tapped", "screen_viewed"
    }
    
    var parameters: [String: Any] {
        // Always include "screen_name" for context
    }
}
```

### Screen Tracking

```swift
.trackScreen("ScreenName")
```

### Button Tracking

```swift
// Option 1: Use TrackedButton component
TrackedButton("ButtonName", screen: "ScreenName") {
    // action
}

// Option 2: Track in ViewModel
func didTapSomething() {
    Analytics.shared.track(.buttonTapped(name: "Something", screen: "ScreenName"))
    // business logic
}
```

### Error Tracking

```swift
catch let error {
    Analytics.shared.track(.errorOccurred(
        type: "network",
        message: error.localizedDescription,
        screen: "ScreenName"
    ))
}
```

## Naming Conventions

- Event names: `snake_case` (e.g., `button_tapped`)
- Format: `[object]_[action]`
- Always include `screen_name` parameter

## Please:

1. Add screen view tracking (`.trackScreen()`)
2. Add tracking for the specified user actions
3. Add any new event cases to `AnalyticsEvent` enum if needed
4. Include error tracking in any `catch` blocks
5. Use consistent naming following our conventions

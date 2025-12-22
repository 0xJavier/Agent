# ViewModel Examples

> **Add your code examples here.** Copilot will reference these when generating ViewModels.

## Your ViewModel Template

Replace with your standard ViewModel structure:

```swift
// TODO: Add your ViewModel template
import SwiftUI

@Observable
final class ExampleViewModel {
    // Your standard properties
    var items: [Item] = []
    var isLoading = false
    var error: Error?
    
    // Your dependency injection pattern
    private let service: ServiceProtocol
    
    init(service: ServiceProtocol = Service()) {
        self.service = service
    }
    
    // Your standard methods
    func load() async {
        // Your loading pattern
    }
}
```

## Your State Management Pattern

```swift
// TODO: Show how you manage loading/error/success states
```

## Your Error Handling Pattern

```swift
// TODO: Show how you handle and surface errors
```

## Your Async Patterns

```swift
// TODO: Show your Task management, cancellation patterns
```

## Your Preview Support

```swift
// TODO: Show how you create preview instances
extension ExampleViewModel {
    static let preview = ExampleViewModel(service: MockService())
}
```

---

## Instructions

Add your real ViewModel examples here. Copilot will generate new ViewModels matching your patterns.

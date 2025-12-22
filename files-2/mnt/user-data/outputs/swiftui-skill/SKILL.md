---
name: swiftui-ios
description: "iOS app development with SwiftUI framework. Use when Claude needs to: (1) Create SwiftUI views, components, or full iOS apps, (2) Implement iOS patterns like MVVM, navigation, data flow, (3) Work with iOS APIs (Core Data, networking, notifications, HealthKit, etc.), (4) Debug or optimize SwiftUI performance, (5) Integrate UIKit with SwiftUI, (6) Handle iOS-specific features like widgets, App Clips, or extensions"
---

# SwiftUI iOS Development

## Overview

SwiftUI is Apple's declarative UI framework for building iOS, macOS, watchOS, and tvOS apps. This skill covers iOS-specific patterns, best practices, and common workflows.

## Architecture Decision

### When to Use Which Pattern

- **Simple apps/prototypes**: Use `@State` and `@Binding` directly in views
- **Medium complexity**: Use `@Observable` classes (iOS 17+) or `ObservableObject` (iOS 14+)
- **Complex apps**: Full MVVM with dependency injection via Environment

## Quick Reference

### View Basics

```swift
struct ContentView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Count: \(count)")
                .font(.title)
            
            Button("Increment") {
                count += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

### Data Flow Patterns

| Property Wrapper | Use Case | Ownership |
|-----------------|----------|-----------|
| `@State` | View-local value types | View owns |
| `@Binding` | Two-way connection to parent's state | Parent owns |
| `@StateObject` | Create & own an ObservableObject | View owns |
| `@ObservedObject` | Reference external ObservableObject | External owns |
| `@EnvironmentObject` | Dependency injection | App/parent owns |
| `@Observable` (iOS 17+) | Modern observation | Flexible |

### Navigation (iOS 16+)

```swift
// Stack-based navigation
NavigationStack {
    List(items) { item in
        NavigationLink(value: item) {
            ItemRow(item: item)
        }
    }
    .navigationDestination(for: Item.self) { item in
        ItemDetailView(item: item)
    }
}
```

## Common Workflows

### Creating a New View

1. Define the struct conforming to `View`
2. Add required state properties
3. Implement `body` computed property
4. Extract reusable subviews when body exceeds ~30 lines

### Implementing MVVM

See [references/mvvm-pattern.md](references/mvvm-pattern.md) for complete guide with examples.

### Networking & Async

See [references/networking.md](references/networking.md) for URLSession, async/await patterns, and error handling.

### Core Data Integration

See [references/core-data.md](references/core-data.md) for persistence patterns with SwiftUI.

### Common UI Patterns

See [references/ui-patterns.md](references/ui-patterns.md) for lists, forms, sheets, alerts, and custom components.

## Performance Guidelines

1. **Minimize view body complexity** - Extract subviews to limit recomputation scope
2. **Use `@ViewBuilder` wisely** - Avoid heavy logic in view builders
3. **Lazy loading** - Use `LazyVStack`/`LazyHStack` for large lists
4. **Avoid AnyView** - Use `@ViewBuilder` or `some View` instead
5. **Profile with Instruments** - Use SwiftUI template to identify redraws

## iOS Version Considerations

| Feature | Minimum iOS |
|---------|-------------|
| Basic SwiftUI | 13.0 |
| `@StateObject` | 14.0 |
| `AsyncImage` | 15.0 |
| `NavigationStack` | 16.0 |
| `@Observable` | 17.0 |

When targeting iOS 14+, prefer `@StateObject` over `@ObservedObject` for owned objects.

## Code Style

- Use trailing closure syntax for modifiers
- Group related modifiers together
- Prefer composition over inheritance
- Keep views small and focused
- Use meaningful names for extracted subviews

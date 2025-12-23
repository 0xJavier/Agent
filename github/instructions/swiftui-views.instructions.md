---
applyTo: "**/Views/**/*.swift,**/Features/**/*View.swift"
description: "SwiftUI view structure and composition patterns"
---

# SwiftUI View Patterns

## View Structure Template

Every feature view follows this structure:

```swift
import SwiftUI

struct FeatureNameView: View {
    // MARK: - Dependencies
    @StateObject private var viewModel: FeatureNameViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Local State
    @State private var isShowingSheet = false
    
    // MARK: - Init
    init(viewModel: FeatureNameViewModel = .init()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        content
            .navigationTitle("Feature Name")
            .trackScreen("FeatureName")
    }
    
    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        // Main content here
    }
}

// MARK: - Subviews
private extension FeatureNameView {
    var headerSection: some View { /* ... */ }
    var listSection: some View { /* ... */ }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FeatureNameView()
    }
}
```

## State Management Rules

| Property Wrapper | When to Use |
|-----------------|-------------|
| `@State` | View-local UI state (isExpanded, selectedTab) |
| `@StateObject` | ViewModel owned by this view |
| `@ObservedObject` | ViewModel passed from parent |
| `@Binding` | Two-way connection to parent's state |

Key rules:
- Create `@StateObject` only in the view that owns it
- Pass down as `@ObservedObject` to child views
- Use `@Binding` for simple value types

## View Composition

Extract subviews when:
- A section exceeds ~30 lines
- Logic is reused in multiple places
- A section has its own state

```swift
// After extraction
var body: some View {
    VStack {
        headerSection
        listSection
        footerSection
    }
}

private var headerSection: some View {
    // Implementation
}
```

## Loading States

```swift
struct AsyncContentView<Content: View>: View {
    let state: LoadingState
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        switch state {
        case .idle: Color.clear
        case .loading: ProgressView()
        case .loaded: content()
        case .error(let message): ErrorView(message: message)
        }
    }
}
```

## ViewModel Integration

```swift
@MainActor
final class FeatureViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var state: LoadingState = .idle
    
    func loadItems() async {
        state = .loading
        do {
            items = try await repository.fetchItems()
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
```

## Checklist

- [ ] Follow view structure template
- [ ] Use appropriate state management
- [ ] Extract subviews for sections over 30 lines
- [ ] Add `.trackScreen()` for analytics
- [ ] Handle loading, error, and empty states
- [ ] Add #Preview

---
mode: 'agent'
description: 'Generate a new SwiftUI view with proper structure, ViewModel, and analytics'
---

Create a new SwiftUI view following our project patterns.

## View Details

- **View name**: ${input:viewName:Enter the view name (e.g., ProductDetail)}
- **Purpose**: ${input:purpose:What does this view do?}
- **Has list/collection?**: ${input:hasList:Does it display a list? (yes/no)}

## Requirements

Follow these patterns from our codebase:

### View Structure
```swift
struct ${viewName}View: View {
    // MARK: - Dependencies
    @StateObject private var viewModel: ${viewName}ViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Local State
    @State private var isShowingSheet = false
    
    // MARK: - Init
    init(viewModel: ${viewName}ViewModel = .init()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        content
            .navigationTitle("${viewName}")
            .trackScreen("${viewName}")
    }
}
```

### ViewModel Structure
```swift
@MainActor
final class ${viewName}ViewModel: ObservableObject {
    @Published private(set) var state: LoadingState = .idle
    
    private let repository: SomeRepository
    
    init(repository: SomeRepository = .shared) {
        self.repository = repository
    }
}
```

## Checklist

Please ensure the generated code includes:
- [ ] Proper MARK comments for organization
- [ ] `@StateObject` for the ViewModel
- [ ] `.trackScreen()` modifier for analytics
- [ ] Loading, error, and empty states if fetching data
- [ ] Extracted subviews for sections over 30 lines
- [ ] `#Preview` at the bottom
- [ ] Accessibility labels on interactive elements

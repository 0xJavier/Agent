---
name: swiftui-views
description: SwiftUI view creation patterns and best practices for iOS. Use this skill when creating new SwiftUI views, building feature screens, implementing reusable components, or refactoring existing views. Covers view structure, state management, composition patterns, and integration with ViewModels.
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
            .trackScreen("FeatureName")  // Analytics
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
| `@EnvironmentObject` | Shared app-wide state |
| `@Binding` | Two-way connection to parent's state |
| `@Environment` | System values (colorScheme, dismiss) |

### Key Rules
- Create `@StateObject` only in the view that owns it
- Pass down as `@ObservedObject` to child views
- Use `@Binding` for simple value types, `@ObservedObject` for complex objects

## View Composition Patterns

### Extract When:
- A section exceeds ~30 lines
- Logic is reused in multiple places
- A section has its own state

### Extraction Pattern:

```swift
// Before: Complex body
var body: some View {
    VStack {
        // 50+ lines of header code
        // 50+ lines of list code
        // 50+ lines of footer code
    }
}

// After: Composed body
var body: some View {
    VStack {
        headerSection
        listSection
        footerSection
    }
}

private var headerSection: some View {
    // Header implementation
}
```

### Reusable Component Pattern:

```swift
// In DesignSystem/Components/
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
```

## Loading States Pattern

Use a consistent pattern for async content:

```swift
struct AsyncContentView<Content: View>: View {
    let state: LoadingState
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        switch state {
        case .idle:
            Color.clear
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            content()
        case .error(let message):
            ErrorView(message: message)
        }
    }
}

// Usage
struct ProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    
    var body: some View {
        AsyncContentView(state: viewModel.state) {
            productList
        }
        .task {
            await viewModel.loadProducts()
        }
    }
}
```

## List Patterns

### Standard List with Pull-to-Refresh:

```swift
var body: some View {
    List {
        ForEach(viewModel.items) { item in
            ItemRow(item: item)
        }
    }
    .refreshable {
        await viewModel.refresh()
    }
    .overlay {
        if viewModel.items.isEmpty && !viewModel.isLoading {
            EmptyStateView(message: "No items yet")
        }
    }
}
```

### Searchable List:

```swift
struct SearchableListView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        List(viewModel.filteredItems) { item in
            ItemRow(item: item)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search items")
    }
}
```

## Navigation Patterns

### NavigationStack with Typed Destinations:

```swift
struct ContentView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Product.self) { product in
                    ProductDetailView(product: product)
                }
                .navigationDestination(for: Category.self) { category in
                    CategoryView(category: category)
                }
        }
    }
}
```

## Sheet/Modal Pattern

```swift
struct ParentView: View {
    @State private var sheetItem: SheetItem?
    
    enum SheetItem: Identifiable {
        case addItem
        case editItem(Item)
        
        var id: String {
            switch self {
            case .addItem: return "add"
            case .editItem(let item): return "edit-\(item.id)"
            }
        }
    }
    
    var body: some View {
        content
            .sheet(item: $sheetItem) { item in
                switch item {
                case .addItem:
                    AddItemView()
                case .editItem(let item):
                    EditItemView(item: item)
                }
            }
    }
}
```

## ViewModel Integration

```swift
@MainActor
final class FeatureViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var items: [Item] = []
    @Published private(set) var state: LoadingState = .idle
    @Published var searchText = ""
    
    // MARK: - Dependencies
    private let repository: ItemRepository
    
    // MARK: - Computed
    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    // MARK: - Init
    init(repository: ItemRepository = .shared) {
        self.repository = repository
    }
    
    // MARK: - Actions
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

## Checklist for New Views

1. [ ] Follow view structure template (Dependencies → State → Init → Body)
2. [ ] Use appropriate state management (@StateObject vs @ObservedObject)
3. [ ] Extract subviews for sections over 30 lines
4. [ ] Add `.trackScreen()` for analytics
5. [ ] Add accessibility labels (see accessibility skill)
6. [ ] Handle loading, error, and empty states
7. [ ] Add #Preview for development

## See Also

- Example implementation: [examples/ExampleFeatureView.swift](examples/ExampleFeatureView.swift)

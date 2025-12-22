# SwiftUI Preview Patterns

## Preview Organization

### State Variants

```swift
struct ButtonPreviews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrimaryButton(title: "Default", action: {})
            PrimaryButton(title: "Loading", action: {}, isLoading: true)
            PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
        }
        .padding()
        .previewDisplayName("Button States")
    }
}

// Modern syntax
#Preview("All States") {
    VStack(spacing: 20) {
        PrimaryButton(title: "Default", action: {})
        PrimaryButton(title: "Loading", action: {}, isLoading: true)
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}
```

### Device Variations

```swift
#Preview("iPhone SE", traits: .fixedLayout(width: 375, height: 667)) {
    ContentView()
}

#Preview("iPhone 15 Pro Max", traits: .fixedLayout(width: 430, height: 932)) {
    ContentView()
}

#Preview("iPad", traits: .fixedLayout(width: 1024, height: 768)) {
    ContentView()
}
```

### Environment Variations

```swift
#Preview("Light Mode") {
    ComponentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ComponentView()
        .preferredColorScheme(.dark)
}

#Preview("Large Text") {
    ComponentView()
        .dynamicTypeSize(.xxxLarge)
}

#Preview("RTL") {
    ComponentView()
        .environment(\.layoutDirection, .rightToLeft)
}
```

### Interactive Previews

```swift
struct InteractivePreview: View {
    @State private var isOn = false
    @State private var text = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Toggle("Enable feature", isOn: $isOn)
            TextField("Enter text", text: $text)
            
            MyComponent(isEnabled: isOn, text: text)
        }
        .padding()
    }
}

#Preview("Interactive") {
    InteractivePreview()
}
```

## Preview Data

### Sample Data Extensions

```swift
extension Task {
    static let sample = Task(
        id: UUID(),
        title: "Sample Task",
        isCompleted: false,
        dueDate: .now.addingTimeInterval(86400)
    )
    
    static let samples: [Task] = [
        Task(id: UUID(), title: "First task", isCompleted: false),
        Task(id: UUID(), title: "Second task", isCompleted: true),
        Task(id: UUID(), title: "Third task with a much longer title that wraps", isCompleted: false),
    ]
    
    static let empty: [Task] = []
    
    static let manyItems: [Task] = (0..<100).map { i in
        Task(id: UUID(), title: "Task \(i)", isCompleted: i % 3 == 0)
    }
}
```

### ViewModel Preview States

```swift
extension TaskListViewModel {
    static var preview: TaskListViewModel {
        let vm = TaskListViewModel()
        vm.tasks = Task.samples
        return vm
    }
    
    static var empty: TaskListViewModel {
        TaskListViewModel()
    }
    
    static var loading: TaskListViewModel {
        let vm = TaskListViewModel()
        vm.isLoading = true
        return vm
    }
    
    static var error: TaskListViewModel {
        let vm = TaskListViewModel()
        vm.error = PreviewError.sample
        return vm
    }
}

enum PreviewError: Error, LocalizedError {
    case sample
    
    var errorDescription: String? {
        "Something went wrong. Please try again."
    }
}
```

## Preview Containers

### Navigation Context

```swift
struct NavigationPreviewContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationStack {
            content
        }
    }
}

#Preview {
    NavigationPreviewContainer {
        DetailView(item: .sample)
    }
}
```

### Sheet Context

```swift
struct SheetPreviewContainer<Content: View>: View {
    @State private var isPresented = true
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        Color.gray.opacity(0.3)
            .sheet(isPresented: $isPresented) {
                content
            }
    }
}
```

### Environment Container

```swift
struct ThemedPreviewContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .environment(\.appTheme, .standard)
            .modelContainer(for: Task.self, inMemory: true)
    }
}
```

## Snapshot-Ready Previews

```swift
// Fixed size for consistent snapshots
#Preview("Card - Snapshot Ready") {
    Card {
        VStack(alignment: .leading) {
            Text("Card Title")
                .font(.headline)
            Text("Card description goes here")
                .font(.body)
        }
    }
    .frame(width: 350)
    .padding()
    .background(Color(.systemBackground))
}
```

## Accessibility Previews

```swift
#Preview("VoiceOver Frames") {
    TaskRow(task: .sample)
        .accessibilityShowFrames()
}

#Preview("Reduce Motion") {
    AnimatedComponent()
        .environment(\.accessibilityReduceMotion, true)
}

#Preview("High Contrast") {
    ComponentView()
        .environment(\.colorSchemeContrast, .increased)
}
```

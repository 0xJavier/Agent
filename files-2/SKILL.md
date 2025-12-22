---
name: swiftui-components
description: Reusable SwiftUI component library with production-ready patterns. Use when building custom UI components, buttons, cards, inputs, modals, lists, or any reusable view elements for iOS apps. Includes accessibility, theming, and component composition patterns. Triggers on requests for SwiftUI component design, custom controls, or reusable UI building blocks.
---

# SwiftUI Component Library

Build consistent, accessible, reusable UI components.

## Component Design Principles

1. **Configurable**: Accept parameters for customization
2. **Accessible**: Include VoiceOver support by default
3. **Themeable**: Use environment for styling
4. **Composable**: Work well with other components
5. **Preview-ready**: Include comprehensive previews

## Button Components

### Primary Button

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isEnabled ? Color.accentColor : Color.gray)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading || isDisabled)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isLoading ? .updatesFrequently : [])
    }
}

// Variants using ViewModifier
struct ButtonStyle: ViewModifier {
    enum Variant { case primary, secondary, destructive, ghost }
    let variant: Variant
    
    func body(content: Content) -> some View {
        content
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                if variant == .secondary || variant == .ghost {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 1)
                }
            }
    }
    
    private var backgroundColor: Color {
        switch variant {
        case .primary: .accentColor
        case .secondary: .clear
        case .destructive: .red
        case .ghost: .clear
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive: .white
        case .secondary, .ghost: .accentColor
        }
    }
    
    private var borderColor: Color {
        variant == .ghost ? .clear : .accentColor
    }
}
```

## Input Components

### TextField with Validation

```swift
struct ValidatedTextField: View {
    let title: String
    @Binding var text: String
    var validation: ((String) -> String?)? = nil
    var keyboardType: UIKeyboardType = .default
    
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            TextField("", text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(borderColor, lineWidth: isFocused ? 2 : 1)
                }
                .focused($isFocused)
                .onChange(of: text) { _, newValue in
                    errorMessage = validation?(newValue)
                }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(text)
        .accessibilityHint(errorMessage ?? "")
    }
    
    private var borderColor: Color {
        if errorMessage != nil { return .red }
        if isFocused { return .accentColor }
        return .clear
    }
}

// Usage
ValidatedTextField(
    title: "Email",
    text: $email,
    validation: { value in
        value.contains("@") ? nil : "Invalid email"
    },
    keyboardType: .emailAddress
)
```

## Card Components

### Flexible Card

```swift
struct Card<Content: View>: View {
    let content: Content
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = 16
    var shadowRadius: CGFloat = 4
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 4,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(color: .black.opacity(0.1), radius: shadowRadius, y: 2)
    }
}

// Interactive Card
struct TappableCard<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Card { content() }
                .scaleEffect(isPressed ? 0.98 : 1)
                .animation(.spring(duration: 0.2), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
```

## List Components

### Swipeable Row

```swift
struct SwipeableRow<Content: View, LeadingActions: View, TrailingActions: View>: View {
    @ViewBuilder let content: () -> Content
    @ViewBuilder let leadingActions: () -> LeadingActions
    @ViewBuilder let trailingActions: () -> TrailingActions
    
    var body: some View {
        content()
            .swipeActions(edge: .leading) { leadingActions() }
            .swipeActions(edge: .trailing) { trailingActions() }
    }
}

// Convenience for common patterns
extension SwipeableRow where LeadingActions == EmptyView {
    init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder trailingActions: @escaping () -> TrailingActions
    ) {
        self.content = content
        self.leadingActions = { EmptyView() }
        self.trailingActions = trailingActions
    }
}

// Usage
SwipeableRow {
    TaskRow(task: task)
} trailingActions: {
    Button(role: .destructive) { delete(task) } label: {
        Label("Delete", systemImage: "trash")
    }
    Button { edit(task) } label: {
        Label("Edit", systemImage: "pencil")
    }
    .tint(.orange)
}
```

## Loading States

### Skeleton View

```swift
struct SkeletonView: View {
    var height: CGFloat = 20
    var cornerRadius: CGFloat = 4
    
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color(.systemGray5))
            .frame(height: height)
            .overlay {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.4), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 0.6)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// Skeleton list item
struct SkeletonListItem: View {
    var body: some View {
        HStack(spacing: 12) {
            SkeletonView(height: 50, cornerRadius: 8)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(height: 16)
                    .frame(width: 150)
                SkeletonView(height: 12)
                    .frame(width: 100)
            }
            
            Spacer()
        }
        .padding()
    }
}
```

## Modal Components

### Bottom Sheet

```swift
struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let detents: Set<PresentationDetent>
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Color.clear
            .sheet(isPresented: $isPresented) {
                content()
                    .presentationDetents(detents)
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(24)
            }
    }
}

// Custom Alert
struct CustomAlert: View {
    let title: String
    let message: String
    let primaryAction: (title: String, action: () -> Void)
    var secondaryAction: (title: String, action: () -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 12) {
                PrimaryButton(title: primaryAction.title, action: primaryAction.action)
                
                if let secondary = secondaryAction {
                    Button(secondary.title, action: secondary.action)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(40)
    }
}
```

## Theming System

```swift
// Theme definition
struct AppTheme {
    var primaryColor: Color
    var backgroundColor: Color
    var textColor: Color
    var cornerRadius: CGFloat
    var spacing: CGFloat
    
    static let standard = AppTheme(
        primaryColor: .blue,
        backgroundColor: Color(.systemBackground),
        textColor: .primary,
        cornerRadius: 12,
        spacing: 16
    )
    
    static let playful = AppTheme(
        primaryColor: .purple,
        backgroundColor: Color(.systemBackground),
        textColor: .primary,
        cornerRadius: 20,
        spacing: 20
    )
}

// Environment key
extension EnvironmentValues {
    @Entry var appTheme: AppTheme = .standard
}

// Usage in components
struct ThemedButton: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(title, action: action)
            .padding(theme.spacing)
            .background(theme.primaryColor)
            .clipShape(RoundedRectangle(cornerRadius: theme.cornerRadius))
    }
}
```

## Preview Patterns

See [references/preview-patterns.md](references/preview-patterns.md) for comprehensive preview organization strategies.

```swift
#Preview("Default") {
    PrimaryButton(title: "Continue", action: {})
        .padding()
}

#Preview("Loading") {
    PrimaryButton(title: "Continue", action: {}, isLoading: true)
        .padding()
}

#Preview("Disabled") {
    PrimaryButton(title: "Continue", action: {}, isDisabled: true)
        .padding()
}

#Preview("Dark Mode") {
    PrimaryButton(title: "Continue", action: {})
        .padding()
        .preferredColorScheme(.dark)
}
```

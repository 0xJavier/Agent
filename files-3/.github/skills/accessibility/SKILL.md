---
name: accessibility
description: iOS accessibility implementation for VoiceOver, Dynamic Type, and other assistive technologies. Use this skill when creating new views, adding accessibility support to existing features, implementing VoiceOver labels, handling Dynamic Type, or ensuring WCAG compliance. Covers SwiftUI accessibility modifiers, testing approaches, and common patterns.
---

# Accessibility Implementation

## Core Requirements

Every interactive element must have:
1. **Accessible label** - What it is
2. **Accessible hint** (if needed) - What it does
3. **Accessible traits** - How it behaves

## Quick Reference

```swift
// Basic label
Button("Submit") { }
    .accessibilityLabel("Submit form")

// Label with hint
Button { } label: { Image(systemName: "heart") }
    .accessibilityLabel("Favorite")
    .accessibilityHint("Double tap to add to favorites")

// Combined elements
HStack {
    Text(item.name)
    Text(item.price)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(item.name), \(item.price)")
```

## Accessibility Labels

### When to Add Labels

| Element | Needs Label? | Example |
|---------|-------------|---------|
| Text-only Button | Usually no | `Button("Save")` - text is the label |
| Icon-only Button | **Always** | `Image(systemName: "trash")` needs label |
| Image | **Always** | Decorative: `.accessibilityHidden(true)` |
| Custom control | **Always** | Sliders, toggles, steppers |
| Combined elements | **Always** | Price + name should be one element |

### Writing Good Labels

```swift
// ❌ Bad: Describes appearance
.accessibilityLabel("Red button with heart icon")

// ✅ Good: Describes purpose
.accessibilityLabel("Add to favorites")

// ❌ Bad: Includes "button" (VoiceOver adds this)
.accessibilityLabel("Submit button")

// ✅ Good: Just the action
.accessibilityLabel("Submit")

// ❌ Bad: Too long
.accessibilityLabel("Tap this button to save your current changes to the document")

// ✅ Good: Concise
.accessibilityLabel("Save changes")
```

## Common Patterns

### Image Buttons

```swift
Button {
    viewModel.toggleFavorite()
} label: {
    Image(systemName: isFavorite ? "heart.fill" : "heart")
}
.accessibilityLabel(isFavorite ? "Remove from favorites" : "Add to favorites")
```

### Decorative Images

```swift
// Hide decorative images from VoiceOver
Image("decorative-banner")
    .accessibilityHidden(true)
```

### Combined Elements

```swift
// Combine related elements into one accessible unit
HStack {
    AsyncImage(url: product.imageURL)
    VStack(alignment: .leading) {
        Text(product.name)
        Text(product.price)
    }
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(product.name), \(product.price)")
.accessibilityAddTraits(.isButton)
```

### Custom Actions

```swift
// Add multiple actions to a single element
ProductRow(product: product)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(product.name)
    .accessibilityAction(named: "Add to cart") {
        viewModel.addToCart(product)
    }
    .accessibilityAction(named: "Add to favorites") {
        viewModel.addToFavorites(product)
    }
```

### Loading States

```swift
ProgressView()
    .accessibilityLabel("Loading")

// With context
ProgressView()
    .accessibilityLabel("Loading products")
```

### Value Announcements

```swift
// Announce value changes
@State private var quantity = 1

Stepper("Quantity", value: $quantity, in: 1...10)
    .accessibilityValue("\(quantity) items")
    .onChange(of: quantity) { _, newValue in
        // VoiceOver will announce the new value
    }
```

## Dynamic Type Support

### Required: Support Dynamic Type

```swift
// ✅ Use built-in text styles
Text("Title")
    .font(.headline)

// ✅ Scale custom fonts
Text("Custom")
    .font(.custom("MyFont", size: 17, relativeTo: .body))

// ❌ Never use fixed sizes without scaling
Text("Fixed")
    .font(.system(size: 17))  // Won't scale with Dynamic Type
```

### Layout Adjustments

```swift
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if dynamicTypeSize >= .accessibility1 {
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
        } else {
            HStack(spacing: 12) {
                content()
            }
        }
    }
}

// Usage
AdaptiveStack {
    Image(systemName: "star")
    Text("Rating")
}
```

### Minimum Tap Targets

```swift
// Ensure 44x44pt minimum tap targets
Button { } label: {
    Image(systemName: "xmark")
        .frame(width: 44, height: 44)
}
```

## Traits

```swift
// Common traits
.accessibilityAddTraits(.isButton)      // Interactive, tappable
.accessibilityAddTraits(.isHeader)       // Section headers
.accessibilityAddTraits(.isSelected)     // Currently selected item
.accessibilityAddTraits(.isModal)        // Modal presentations
.accessibilityAddTraits(.updatesFrequently)  // Live-updating content

// Remove default traits if needed
.accessibilityRemoveTraits(.isImage)
```

## Focus Management

```swift
struct SearchView: View {
    @AccessibilityFocusState private var isSearchFocused: Bool
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            TextField("Search", text: $searchText)
                .accessibilityFocused($isSearchFocused)
            
            Button("Clear") {
                searchText = ""
                isSearchFocused = true  // Return focus to search field
            }
        }
    }
}
```

## Testing Checklist

### Manual Testing
1. [ ] Enable VoiceOver (Settings → Accessibility → VoiceOver)
2. [ ] Navigate through entire screen with swipe gestures
3. [ ] Verify all interactive elements are reachable
4. [ ] Verify labels are descriptive and concise
5. [ ] Test with largest Dynamic Type size
6. [ ] Test in both Light and Dark mode for contrast

### Automated Testing

```swift
func testAccessibility() throws {
    let app = XCUIApplication()
    app.launch()
    
    // Verify element exists and has label
    let submitButton = app.buttons["Submit form"]
    XCTAssertTrue(submitButton.exists)
    
    // Check accessibility label
    XCTAssertEqual(submitButton.label, "Submit form")
}
```

### Accessibility Inspector
Use Xcode's Accessibility Inspector (Xcode → Open Developer Tool → Accessibility Inspector) to audit views.

## Checklist for New Views

1. [ ] All images have labels or are hidden from VoiceOver
2. [ ] All buttons/interactive elements have descriptive labels
3. [ ] Related elements are combined with `.accessibilityElement(children: .combine)`
4. [ ] Headers marked with `.accessibilityAddTraits(.isHeader)`
5. [ ] Dynamic Type supported (no fixed font sizes)
6. [ ] Minimum 44x44pt tap targets
7. [ ] Loading states announced
8. [ ] Error states announced
9. [ ] Tested with VoiceOver enabled

## See Also

- Example implementation: [examples/AccessibleView.swift](examples/AccessibleView.swift)

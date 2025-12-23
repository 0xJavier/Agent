---
applyTo: "**/Views/**/*.swift,**/Features/**/*View.swift,**/DesignSystem/**/*.swift"
description: "Accessibility requirements for VoiceOver, Dynamic Type, and assistive technologies"
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

## When to Add Labels

| Element | Needs Label? |
|---------|-------------|
| Text-only Button | Usually no (text is the label) |
| Icon-only Button | **Always** |
| Image | **Always** (or hide with `.accessibilityHidden(true)`) |
| Custom control | **Always** |
| Combined elements | **Always** |

## Writing Good Labels

```swift
// ❌ Bad: Describes appearance
.accessibilityLabel("Red button with heart icon")

// ✅ Good: Describes purpose
.accessibilityLabel("Add to favorites")

// ❌ Bad: Includes "button"
.accessibilityLabel("Submit button")

// ✅ Good: Just the action
.accessibilityLabel("Submit")
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
Image("decorative-banner")
    .accessibilityHidden(true)
```

### Combined Elements

```swift
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
ProductRow(product: product)
    .accessibilityAction(named: "Add to cart") {
        viewModel.addToCart(product)
    }
    .accessibilityAction(named: "Add to favorites") {
        viewModel.addToFavorites(product)
    }
```

## Dynamic Type Support

```swift
// ✅ Use built-in text styles
Text("Title").font(.headline)

// ✅ Scale custom fonts
Text("Custom").font(.custom("MyFont", size: 17, relativeTo: .body))

// ❌ Never use fixed sizes
Text("Fixed").font(.system(size: 17))  // Won't scale
```

### Adaptive Layout

```swift
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if dynamicTypeSize >= .accessibility1 {
            VStack(alignment: .leading) { content() }
        } else {
            HStack { content() }
        }
    }
}
```

## Minimum Tap Targets

```swift
// Ensure 44x44pt minimum
Button { } label: {
    Image(systemName: "xmark")
        .frame(width: 44, height: 44)
}
```

## Checklist

- [ ] All images have labels or are hidden
- [ ] All buttons have descriptive labels
- [ ] Related elements combined with `.accessibilityElement(children: .combine)`
- [ ] Headers marked with `.accessibilityAddTraits(.isHeader)`
- [ ] Dynamic Type supported (no fixed font sizes)
- [ ] Minimum 44x44pt tap targets
- [ ] Tested with VoiceOver enabled

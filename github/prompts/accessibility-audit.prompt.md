---
mode: 'agent'
description: 'Audit a SwiftUI view for accessibility issues and suggest fixes'
---

Review the specified view for accessibility compliance and suggest improvements.

## Target

- **View to audit**: ${input:viewPath:Path to the SwiftUI view file}

## Accessibility Checklist

Please check for and fix the following:

### 1. Labels & Hints

- [ ] All icon-only buttons have `.accessibilityLabel()`
- [ ] Labels describe purpose, not appearance
- [ ] Labels don't include "button" (VoiceOver adds this)
- [ ] Complex actions have `.accessibilityHint()`

```swift
// ✅ Good
Button { } label: { Image(systemName: "heart") }
    .accessibilityLabel("Add to favorites")

// ❌ Bad
.accessibilityLabel("Heart button")
```

### 2. Combined Elements

- [ ] Related info grouped with `.accessibilityElement(children: .combine)`
- [ ] Combined elements have meaningful composite labels

```swift
HStack {
    Text(product.name)
    Text(product.price)
}
.accessibilityElement(children: .combine)
.accessibilityLabel("\(product.name), \(product.price)")
```

### 3. Images

- [ ] Informative images have labels
- [ ] Decorative images hidden with `.accessibilityHidden(true)`

### 4. Dynamic Type

- [ ] No fixed font sizes (`.font(.system(size: 17))`)
- [ ] Uses built-in text styles (`.font(.headline)`)
- [ ] Layout adapts for larger text sizes

### 5. Tap Targets

- [ ] All interactive elements are at least 44x44pt

```swift
Button { } label: {
    Image(systemName: "xmark")
        .frame(width: 44, height: 44)
}
```

### 6. Traits

- [ ] Headers marked with `.accessibilityAddTraits(.isHeader)`
- [ ] Buttons have button trait (automatic for Button)
- [ ] Selected states use `.accessibilityAddTraits(.isSelected)`

### 7. Custom Actions

- [ ] Elements with multiple actions use `.accessibilityAction(named:)`

## Output

Please provide:
1. List of accessibility issues found
2. Code fixes for each issue
3. Any additional recommendations

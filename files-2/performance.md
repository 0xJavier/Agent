# SwiftUI Performance Optimization

## View Identity & Redraw Optimization

### Use Stable Identifiers

```swift
// ❌ Bad: Index-based, causes issues with reordering
ForEach(Array(items.enumerated()), id: \.offset) { index, item in
    ItemRow(item: item)
}

// ✅ Good: Stable identifier
ForEach(items) { item in  // Item conforms to Identifiable
    ItemRow(item: item)
}
```

### Minimize View Updates with Equatable

```swift
struct ExpensiveView: View, Equatable {
    let data: ComplexData
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data.id == rhs.data.id && lhs.data.version == rhs.data.version
    }
    
    var body: some View {
        // Complex rendering
    }
}

// Usage
ExpensiveView(data: data)
    .equatable()
```

### Extract Static Content

```swift
// ❌ Bad: Header recreated on every update
struct ListView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        VStack {
            Text("My List")
                .font(.largeTitle)
            ForEach(items) { ItemRow(item: $0) }
        }
    }
}

// ✅ Good: Header extracted
struct ListView: View {
    @State private var items: [Item] = []
    
    var body: some View {
        VStack {
            ListHeader()  // Static, won't redraw
            ForEach(items) { ItemRow(item: $0) }
        }
    }
}

struct ListHeader: View {
    var body: some View {
        Text("My List").font(.largeTitle)
    }
}
```

## Lazy Loading

### Use Lazy Containers

```swift
// ❌ Bad: All items rendered immediately
ScrollView {
    VStack {
        ForEach(largeDataSet) { item in
            ExpensiveItemView(item: item)
        }
    }
}

// ✅ Good: Only visible items rendered
ScrollView {
    LazyVStack {
        ForEach(largeDataSet) { item in
            ExpensiveItemView(item: item)
        }
    }
}
```

### Pagination

```swift
struct PaginatedList: View {
    @State private var items: [Item] = []
    @State private var isLoadingMore = false
    
    var body: some View {
        List {
            ForEach(items) { item in
                ItemRow(item: item)
                    .onAppear {
                        if item == items.last {
                            loadMore()
                        }
                    }
            }
            
            if isLoadingMore {
                ProgressView()
            }
        }
    }
    
    func loadMore() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        // Fetch next page
    }
}
```

## Image Optimization

### Async Image Loading

```swift
AsyncImage(url: imageURL) { phase in
    switch phase {
    case .empty:
        ProgressView()
    case .success(let image):
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
    case .failure:
        Image(systemName: "photo")
            .foregroundStyle(.secondary)
    @unknown default:
        EmptyView()
    }
}
.frame(width: 100, height: 100)
.clipped()
```

### Image Caching

```swift
// Using a cache layer
actor ImageCache {
    static let shared = ImageCache()
    private var cache = NSCache<NSURL, UIImage>()
    
    func image(for url: URL) async throws -> UIImage {
        if let cached = cache.object(forKey: url as NSURL) {
            return cached
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw ImageError.invalidData
        }
        
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}
```

### Downsampling Large Images

```swift
extension UIImage {
    static func downsample(data: Data, to size: CGSize, scale: CGFloat = UIScreen.main.scale) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }
        
        let maxDimension = max(size.width, size.height) * scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
}
```

## Animation Performance

### Prefer Animatable Properties

```swift
// ✅ Efficient: opacity, scale, offset are GPU-optimized
withAnimation {
    isVisible.toggle()
}

Rectangle()
    .opacity(isVisible ? 1 : 0)
    .scaleEffect(isVisible ? 1 : 0.8)
    .offset(y: isVisible ? 0 : 20)

// ❌ Expensive: Layout changes
withAnimation {
    showExtraContent.toggle()
}

VStack {
    if showExtraContent {
        ExtraContent()  // Causes layout recalculation
    }
}
```

### Use drawingGroup for Complex Compositions

```swift
ZStack {
    ForEach(0..<100) { i in
        Circle()
            .fill(colors[i % colors.count])
            .frame(width: 20, height: 20)
            .offset(x: offsets[i].x, y: offsets[i].y)
    }
}
.drawingGroup()  // Flattens to single GPU layer
```

## Profiling Tools

### Instruments
- **Time Profiler**: Find CPU bottlenecks
- **SwiftUI View Body**: Track view body invocations
- **Core Animation**: GPU performance
- **Allocations**: Memory usage

### Debug Overlays

```swift
// In Debug builds
extension View {
    func debugRedraw(_ label: String) -> some View {
        #if DEBUG
        Self._printChanges()
        print("🔄 \(label) body called")
        #endif
        return self
    }
}
```

### Xcode Debug Options
- Enable "View Body Invocations" in Instruments
- Use `Self._printChanges()` in view body (debug only)
- Profile on real device, not simulator

## Common Performance Pitfalls

| Issue | Solution |
|-------|----------|
| Expensive computations in body | Move to `.task` or computed property with caching |
| Large lists without LazyVStack | Use `LazyVStack` or `List` |
| Images not sized correctly | Downsample to display size |
| Too many state updates | Batch updates, use `@Observable` |
| Complex view hierarchies | Break into smaller components |
| Animations on layout changes | Animate opacity/scale/offset instead |

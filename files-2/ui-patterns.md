# SwiftUI UI Patterns

## Table of Contents

1. [Lists](#lists)
2. [Forms](#forms)
3. [Navigation](#navigation)
4. [Sheets & Modals](#sheets--modals)
5. [Alerts & Confirmations](#alerts--confirmations)
6. [Custom Components](#custom-components)
7. [Gestures](#gestures)
8. [Animations](#animations)

## Lists

### Basic List with Selection

```swift
struct ItemListView: View {
    let items: [Item]
    @State private var selection: Item.ID?
    
    var body: some View {
        List(items, selection: $selection) { item in
            ItemRow(item: item)
        }
    }
}
```

### Swipe Actions

```swift
List {
    ForEach(items) { item in
        ItemRow(item: item)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    delete(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions(edge: .leading) {
                Button {
                    toggleFavorite(item)
                } label: {
                    Label("Favorite", systemImage: "star")
                }
                .tint(.yellow)
            }
    }
}
```

### Pull to Refresh

```swift
List(items) { item in
    ItemRow(item: item)
}
.refreshable {
    await loadItems()
}
```

### Searchable List

```swift
struct SearchableListView: View {
    @State private var searchText = ""
    let items: [Item]
    
    var filteredItems: [Item] {
        guard !searchText.isEmpty else { return items }
        return items.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List(filteredItems) { item in
                ItemRow(item: item)
            }
            .searchable(text: $searchText, prompt: "Search items")
            .searchSuggestions {
                ForEach(suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .searchCompletion(suggestion)
                }
            }
        }
    }
}
```

## Forms

### Complete Form Example

```swift
struct SettingsForm: View {
    @State private var username = ""
    @State private var email = ""
    @State private var notificationsEnabled = true
    @State private var frequency: NotificationFrequency = .daily
    @State private var volume = 0.5
    @State private var birthDate = Date()
    
    var body: some View {
        Form {
            Section("Profile") {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                
                DatePicker("Birthday", selection: $birthDate, displayedComponents: .date)
            }
            
            Section("Notifications") {
                Toggle("Enable Notifications", isOn: $notificationsEnabled)
                
                if notificationsEnabled {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(NotificationFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }
            }
            
            Section {
                LabeledContent("Volume") {
                    Slider(value: $volume)
                        .frame(width: 150)
                }
            } footer: {
                Text("Adjust notification volume")
            }
            
            Section {
                Button("Save Changes") {
                    save()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
```

### Form Validation

```swift
struct ValidatedForm: View {
    @State private var email = ""
    @State private var password = ""
    
    var isEmailValid: Bool {
        email.contains("@") && email.contains(".")
    }
    
    var isPasswordValid: Bool {
        password.count >= 8
    }
    
    var isFormValid: Bool {
        isEmailValid && isPasswordValid
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                
                if !email.isEmpty && !isEmailValid {
                    Text("Please enter a valid email")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            Section {
                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                
                if !password.isEmpty && !isPasswordValid {
                    Text("Password must be at least 8 characters")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            Button("Submit") {
                submit()
            }
            .disabled(!isFormValid)
        }
    }
}
```

## Navigation

### Tab View

```swift
struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(2)
                .badge(5)  // Show badge
        }
    }
}
```

### Programmatic Navigation

```swift
struct ContentView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                Button("Go to Detail") {
                    path.append(Item(id: 1, title: "Detail"))
                }
                
                Button("Go to Settings") {
                    path.append("settings")
                }
            }
            .navigationDestination(for: Item.self) { item in
                ItemDetailView(item: item)
            }
            .navigationDestination(for: String.self) { value in
                if value == "settings" {
                    SettingsView()
                }
            }
        }
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
```

## Sheets & Modals

### Basic Sheet

```swift
struct ParentView: View {
    @State private var showSheet = false
    @State private var selectedItem: Item?
    
    var body: some View {
        VStack {
            Button("Show Sheet") {
                showSheet = true
            }
            
            Button("Show Item Sheet") {
                selectedItem = Item(id: 1, title: "Test")
            }
        }
        .sheet(isPresented: $showSheet) {
            SheetContent()
        }
        .sheet(item: $selectedItem) { item in
            ItemDetailSheet(item: item)
        }
    }
}
```

### Detents (iOS 16+)

```swift
.sheet(isPresented: $showSheet) {
    SheetContent()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
}
```

### Full Screen Cover

```swift
.fullScreenCover(isPresented: $showOnboarding) {
    OnboardingView()
}
```

### Popover

```swift
Button("Info") {
    showPopover = true
}
.popover(isPresented: $showPopover) {
    Text("Additional information")
        .padding()
        .presentationCompactAdaptation(.popover)
}
```

## Alerts & Confirmations

### Basic Alert

```swift
@State private var showAlert = false
@State private var alertError: Error?

var body: some View {
    Button("Delete") {
        showAlert = true
    }
    .alert("Confirm Delete", isPresented: $showAlert) {
        Button("Cancel", role: .cancel) { }
        Button("Delete", role: .destructive) {
            performDelete()
        }
    } message: {
        Text("This action cannot be undone.")
    }
}
```

### Error Alert

```swift
.alert("Error", isPresented: .constant(alertError != nil), presenting: alertError) { _ in
    Button("OK") { alertError = nil }
} message: { error in
    Text(error.localizedDescription)
}
```

### Confirmation Dialog

```swift
.confirmationDialog("Select Option", isPresented: $showOptions, titleVisibility: .visible) {
    Button("Option 1") { select(.option1) }
    Button("Option 2") { select(.option2) }
    Button("Delete", role: .destructive) { delete() }
    Button("Cancel", role: .cancel) { }
}
```

## Custom Components

### Reusable Card

```swift
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// Usage
CardView {
    VStack(alignment: .leading) {
        Text("Title").font(.headline)
        Text("Description").foregroundStyle(.secondary)
    }
}
```

### Loading Button

```swift
struct LoadingButton: View {
    let title: String
    let isLoading: Bool
    let action: () async -> Void
    
    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                }
                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }
}
```

### Avatar View

```swift
struct AvatarView: View {
    let url: URL?
    let size: CGFloat
    let placeholder: String
    
    init(url: URL?, size: CGFloat = 40, placeholder: String = "person.fill") {
        self.url = url
        self.size = size
        self.placeholder = placeholder
    }
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                Image(systemName: placeholder)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(.quaternary, lineWidth: 1))
    }
}
```

## Gestures

### Tap and Long Press

```swift
Text("Tap me")
    .onTapGesture {
        handleTap()
    }
    .onLongPressGesture(minimumDuration: 0.5) {
        handleLongPress()
    }
```

### Drag Gesture

```swift
struct DraggableView: View {
    @State private var offset = CGSize.zero
    @State private var isDragging = false
    
    var body: some View {
        Circle()
            .fill(isDragging ? .blue : .red)
            .frame(width: 100, height: 100)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                        isDragging = true
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            offset = .zero
                            isDragging = false
                        }
                    }
            )
    }
}
```

## Animations

### Implicit Animation

```swift
struct AnimatedView: View {
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.blue)
                .frame(width: isExpanded ? 200 : 100, height: isExpanded ? 200 : 100)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isExpanded)
            
            Button("Toggle") {
                isExpanded.toggle()
            }
        }
    }
}
```

### Explicit Animation

```swift
Button("Animate") {
    withAnimation(.easeInOut(duration: 0.3)) {
        isExpanded.toggle()
    }
}
```

### Transition

```swift
struct TransitionExample: View {
    @State private var showDetail = false
    
    var body: some View {
        VStack {
            if showDetail {
                DetailView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            
            Button("Toggle") {
                withAnimation {
                    showDetail.toggle()
                }
            }
        }
    }
}
```

### Phase Animator (iOS 17+)

```swift
struct PulsingView: View {
    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 100, height: 100)
            .phaseAnimator([false, true]) { content, phase in
                content
                    .scaleEffect(phase ? 1.2 : 1.0)
                    .opacity(phase ? 0.8 : 1.0)
            } animation: { _ in
                .easeInOut(duration: 0.8)
            }
    }
}
```

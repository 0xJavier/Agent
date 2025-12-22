# Example Prompts for GitHub Copilot

These are example prompts you would type in Copilot Chat to use your skills.

---

## 🎨 SwiftUI Screen Examples

### Example 1: Basic Screen

**You type in Copilot Chat:**
```
/create-view

Create a ProfileView that displays:
- User avatar (circular image)
- Name and email
- Stats row showing posts, followers, following counts
- Edit Profile button
- List of recent posts

The view should have a ProfileViewModel injected.
```

**What Copilot generates** (using your swiftui.instructions.md + ViewExamples.md):

```swift
import SwiftUI

struct ProfileView: View {
    // MARK: - Properties
    @State private var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Init
    init(viewModel: ProfileViewModel = ProfileViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statsSection
                editButton
                recentPostsSection
            }
            .padding()
        }
        .navigationTitle("Profile")
        .task { await viewModel.load() }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong")
        }
    }
}

// MARK: - Subviews
private extension ProfileView {
    var headerSection: some View {
        VStack(spacing: 12) {
            AsyncImage(url: viewModel.user?.avatarURL) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Circle()
                    .fill(.gray.opacity(0.3))
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            Text(viewModel.user?.name ?? "")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(viewModel.user?.email ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    var statsSection: some View {
        HStack(spacing: 32) {
            statItem(count: viewModel.user?.postsCount ?? 0, label: "Posts")
            statItem(count: viewModel.user?.followersCount ?? 0, label: "Followers")
            statItem(count: viewModel.user?.followingCount ?? 0, label: "Following")
        }
    }
    
    func statItem(count: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    var editButton: some View {
        Button("Edit Profile") {
            viewModel.editProfileTapped()
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Edit your profile")
    }
    
    var recentPostsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Posts")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(viewModel.recentPosts) { post in
                    PostRow(post: post)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        ProfileView(viewModel: .preview)
    }
}

#Preview("Loading") {
    NavigationStack {
        ProfileView(viewModel: .loading)
    }
}
```

---

### Example 2: List Screen with Search

**You type:**
```
/create-view

Create a ProductListView with:
- Search bar
- Filter button in toolbar
- Grid of product cards (2 columns)
- Pull to refresh
- Empty state when no products
- Loading state

Use ProductListViewModel.
```

---

### Example 3: Form Screen

**You type:**
```
/create-view

Create a CheckoutView with:
- Shipping address form (name, street, city, zip)
- Payment method selector
- Order summary showing items and total
- Place Order button (disabled until form valid)
- Loading overlay when submitting
```

---

## 📊 Analytics Examples

### Example 1: Add Screen Tracking

**You type in Copilot Chat:**
```
/add-analytics

Add analytics to this ProfileView:
- Track when screen appears
- Track when Edit Profile is tapped
- Track when a post is selected
```

**What Copilot adds** (using your analytics.instructions.md):

```swift
import SwiftUI

struct ProfileView: View {
    @State private var viewModel: ProfileViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                statsSection
                editButton
                recentPostsSection
            }
            .padding()
        }
        .navigationTitle("Profile")
        // ✅ Added: Screen tracking
        .onAppear {
            Analytics.track(ScreenEvent.viewed(screen: .profile))
        }
        .task { await viewModel.load() }
    }
}

private extension ProfileView {
    var editButton: some View {
        Button("Edit Profile") {
            // ✅ Added: Button tap tracking
            Analytics.track(UserActionEvent.buttonTapped(
                name: "edit_profile",
                screen: "profile"
            ))
            viewModel.editProfileTapped()
        }
        .buttonStyle(.borderedProminent)
    }
    
    var recentPostsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Posts")
                .font(.headline)
            
            ForEach(viewModel.recentPosts) { post in
                PostRow(post: post)
                    .onTapGesture {
                        // ✅ Added: Item selection tracking
                        Analytics.track(UserActionEvent.itemSelected(
                            id: post.id,
                            type: "post",
                            position: viewModel.recentPosts.firstIndex(of: post)
                        ))
                        viewModel.selectPost(post)
                    }
            }
        }
    }
}
```

---

### Example 2: Add Conversion Tracking

**You type:**
```
/add-analytics

Add analytics to this CheckoutViewModel:
- Track when checkout starts
- Track when payment method is selected  
- Track purchase completion with amount and item count
- Track checkout errors
```

**What Copilot adds:**

```swift
@Observable
final class CheckoutViewModel {
    var cart: Cart
    var selectedPayment: PaymentMethod?
    var isProcessing = false
    var error: Error?
    
    init(cart: Cart) {
        self.cart = cart
        
        // ✅ Track checkout started
        Analytics.track(UserActionEvent.flowStarted(
            name: "checkout",
            properties: ["item_count": cart.items.count]
        ))
    }
    
    func selectPayment(_ method: PaymentMethod) {
        selectedPayment = method
        
        // ✅ Track payment method selection
        Analytics.track(UserActionEvent.itemSelected(
            id: method.id,
            type: "payment_method",
            position: nil
        ))
    }
    
    func placeOrder() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let order = try await orderService.place(cart: cart, payment: selectedPayment!)
            
            // ✅ Track successful purchase
            Analytics.track(ConversionEvent.purchaseCompleted(
                amount: cart.total,
                currency: "USD",
                itemCount: cart.items.count
            ))
            
        } catch {
            self.error = error
            
            // ✅ Track checkout error
            Analytics.track(ErrorEvent.occurred(
                name: "checkout_failed",
                reason: error.localizedDescription
            ))
        }
    }
}
```

---

### Example 3: Add Analytics to Existing Feature

**You type:**
```
/add-analytics

Add comprehensive analytics to this SearchView:
- Screen view
- Search submitted (track query length, not the query itself)
- Filter applied
- Result tapped (with position)
- No results state
```

---

## 🧪 Testing Example

**You type:**
```
/create-tests

Generate tests for ProfileViewModel covering:
- Loading user data successfully
- Handling network errors
- Edit profile navigation
- Refreshing data
```

---

## 🌐 API Example

**You type:**
```
/create-api

Create a ProductService with:
- GET /products (list with pagination)
- GET /products/:id (single product)
- POST /products/:id/favorite (toggle favorite)
- GET /products/search?q= (search)

Product has: id, name, price, imageURL, isFavorite
```

---

## 💡 Tips for Better Prompts

### Be Specific
```
❌ "Create a view for users"
✅ "Create a UserProfileView showing avatar, name, bio, and a Follow button"
```

### Mention the ViewModel
```
❌ "Create a settings screen"
✅ "Create SettingsView with SettingsViewModel. Include toggles for notifications, dark mode, and a logout button"
```

### Specify States
```
✅ "Include loading state, empty state, and error handling"
```

### Reference Your Patterns
```
✅ "Use our standard card component for each item"
✅ "Follow the same pattern as HomeView"
```

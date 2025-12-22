import SwiftUI

// MARK: - Accessible Product Card Example

/// Demonstrates comprehensive accessibility implementation
struct AccessibleProductCard: View {
    let product: Product
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    let onAddToCart: () -> Void
    
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        cardContent
            // Combine all elements into one accessible unit
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Double tap to view details")
            .accessibilityAddTraits(.isButton)
            // Add custom actions for VoiceOver users
            .accessibilityAction(named: favoriteActionLabel) {
                onFavoriteToggle()
            }
            .accessibilityAction(named: "Add to cart") {
                onAddToCart()
            }
    }
    
    // MARK: - Content
    
    @ViewBuilder
    private var cardContent: some View {
        // Switch to vertical layout at larger text sizes
        if dynamicTypeSize >= .accessibility1 {
            VStack(alignment: .leading, spacing: 12) {
                productImage
                productDetails
            }
        } else {
            HStack(spacing: 16) {
                productImage
                productDetails
                Spacer()
                favoriteButton
            }
        }
    }
    
    private var productImage: some View {
        AsyncImage(url: product.imageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
        }
        .frame(width: imageSize, height: imageSize)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        // Decorative image - details provided by parent's label
        .accessibilityHidden(true)
    }
    
    private var productDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(.headline)
            
            Text(product.category)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text(product.formattedPrice)
                .font(.title3.bold())
                .foregroundStyle(.primary)
            
            if product.isOnSale {
                saleTag
            }
        }
    }
    
    private var saleTag: some View {
        Text("On Sale")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.red)
            .clipShape(Capsule())
    }
    
    private var favoriteButton: some View {
        Button(action: onFavoriteToggle) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundStyle(isFavorite ? .red : .gray)
                // Ensure minimum tap target of 44x44
                .frame(width: 44, height: 44)
        }
        // Individual accessibility for the button when shown
        .accessibilityLabel(favoriteActionLabel)
    }
    
    // MARK: - Computed Properties
    
    private var imageSize: CGFloat {
        dynamicTypeSize >= .accessibility1 ? 120 : 80
    }
    
    private var accessibilityLabel: String {
        var label = "\(product.name), \(product.formattedPrice)"
        if product.isOnSale {
            label += ", on sale"
        }
        if isFavorite {
            label += ", favorited"
        }
        return label
    }
    
    private var favoriteActionLabel: String {
        isFavorite ? "Remove from favorites" : "Add to favorites"
    }
}

// MARK: - Accessible List View

struct AccessibleProductListView: View {
    @StateObject private var viewModel = ProductListViewModel()
    @State private var announcementMessage = ""
    
    var body: some View {
        List {
            // Section with proper header trait
            Section {
                ForEach(viewModel.featuredProducts) { product in
                    productRow(product)
                }
            } header: {
                Text("Featured")
                    .accessibilityAddTraits(.isHeader)
            }
            
            Section {
                ForEach(viewModel.allProducts) { product in
                    productRow(product)
                }
            } header: {
                Text("All Products")
                    .accessibilityAddTraits(.isHeader)
            }
        }
        .accessibilityLabel("Product list")
        // Announce changes to VoiceOver
        .accessibilityAnnouncement(announcementMessage)
        .refreshable {
            await viewModel.refresh()
            announcementMessage = "Products refreshed"
        }
    }
    
    private func productRow(_ product: Product) -> some View {
        AccessibleProductCard(
            product: product,
            isFavorite: viewModel.isFavorite(product),
            onFavoriteToggle: {
                viewModel.toggleFavorite(product)
                let action = viewModel.isFavorite(product) ? "added to" : "removed from"
                announcementMessage = "\(product.name) \(action) favorites"
            },
            onAddToCart: {
                viewModel.addToCart(product)
                announcementMessage = "\(product.name) added to cart"
            }
        )
    }
}

// MARK: - Accessible Form Example

struct AccessibleFormView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var quantity = 1
    @State private var agreeToTerms = false
    @State private var showError = false
    
    @AccessibilityFocusState private var focusedField: FormField?
    
    enum FormField {
        case name, email, quantity
    }
    
    var body: some View {
        Form {
            Section {
                TextField("Full Name", text: $name)
                    .accessibilityLabel("Full name, required")
                    .accessibilityFocused($focusedField, equals: .name)
                
                TextField("Email Address", text: $email)
                    .keyboardType(.emailAddress)
                    .accessibilityLabel("Email address, required")
                    .accessibilityFocused($focusedField, equals: .email)
            } header: {
                Text("Contact Information")
                    .accessibilityAddTraits(.isHeader)
            }
            
            Section {
                Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)
                    .accessibilityValue("\(quantity) items")
                    .accessibilityFocused($focusedField, equals: .quantity)
            } header: {
                Text("Order Details")
                    .accessibilityAddTraits(.isHeader)
            }
            
            Section {
                Toggle(isOn: $agreeToTerms) {
                    Text("I agree to the Terms and Conditions")
                }
                .accessibilityHint("Required to complete purchase")
            }
            
            Section {
                Button("Complete Purchase") {
                    validateAndSubmit()
                }
                .frame(maxWidth: .infinity)
                .accessibilityHint(submitButtonHint)
            }
        }
        .alert("Missing Information", isPresented: $showError) {
            Button("OK") {
                // Focus the first empty required field
                if name.isEmpty {
                    focusedField = .name
                } else if email.isEmpty {
                    focusedField = .email
                }
            }
        } message: {
            Text("Please fill in all required fields.")
        }
    }
    
    private var submitButtonHint: String {
        if !agreeToTerms {
            return "First agree to Terms and Conditions"
        }
        return "Double tap to complete your purchase"
    }
    
    private func validateAndSubmit() {
        if name.isEmpty || email.isEmpty || !agreeToTerms {
            showError = true
        } else {
            // Submit form
        }
    }
}

// MARK: - Dynamic Type Adaptive Stack

/// Switches between horizontal and vertical layout based on text size
struct AdaptiveStack<Content: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content
    
    init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        if dynamicTypeSize >= .accessibility1 {
            VStack(alignment: horizontalAlignment, spacing: spacing) {
                content()
            }
        } else {
            HStack(alignment: verticalAlignment, spacing: spacing) {
                content()
            }
        }
    }
}

// MARK: - Accessibility Announcement Modifier

struct AccessibilityAnnouncementModifier: ViewModifier {
    let message: String
    
    func body(content: Content) -> some View {
        content
            .onChange(of: message) { _, newValue in
                guard !newValue.isEmpty else { return }
                UIAccessibility.post(
                    notification: .announcement,
                    argument: newValue
                )
            }
    }
}

extension View {
    func accessibilityAnnouncement(_ message: String) -> some View {
        modifier(AccessibilityAnnouncementModifier(message: message))
    }
}

// MARK: - Supporting Types

extension Product {
    var isOnSale: Bool { false } // Placeholder
}

extension ProductListViewModel {
    var featuredProducts: [Product] { [] }
    var allProducts: [Product] { products }
    func isFavorite(_ product: Product) -> Bool { false }
    func toggleFavorite(_ product: Product) {}
    func addToCart(_ product: Product) {}
}

// MARK: - Preview

#Preview("Accessible Card") {
    AccessibleProductCard(
        product: Product(
            id: "1",
            name: "Wireless Headphones",
            category: "Electronics",
            price: 99.99,
            imageURL: nil
        ),
        isFavorite: true,
        onFavoriteToggle: {},
        onAddToCart: {}
    )
    .padding()
}

#Preview("Accessible Form") {
    NavigationStack {
        AccessibleFormView()
            .navigationTitle("Checkout")
    }
}

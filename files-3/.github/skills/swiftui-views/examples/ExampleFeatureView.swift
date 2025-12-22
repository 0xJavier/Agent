import SwiftUI

// MARK: - Feature View Example

/// Example feature view demonstrating standard patterns
struct ProductListView: View {
    // MARK: - Dependencies
    @StateObject private var viewModel: ProductListViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Local State
    @State private var selectedProduct: Product?
    @State private var isShowingAddSheet = false
    
    // MARK: - Init
    init(viewModel: ProductListViewModel = .init()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    var body: some View {
        content
            .navigationTitle("Products")
            .toolbar { toolbarContent }
            .searchable(text: $viewModel.searchText, prompt: "Search products")
            .refreshable { await viewModel.refresh() }
            .sheet(isPresented: $isShowingAddSheet) { AddProductView() }
            .sheet(item: $selectedProduct) { ProductDetailView(product: $0) }
            .trackScreen("ProductList")
            .task { await viewModel.loadProducts() }
    }
    
    // MARK: - Content
    @ViewBuilder
    private var content: some View {
        AsyncContentView(state: viewModel.state) {
            productList
        }
    }
}

// MARK: - Subviews

private extension ProductListView {
    var productList: some View {
        List {
            ForEach(viewModel.filteredProducts) { product in
                ProductRow(product: product)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProduct = product
                    }
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteProducts(at: indexSet)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.filteredProducts.isEmpty {
                emptyState
            }
        }
    }
    
    var emptyState: some View {
        ContentUnavailableView(
            "No Products",
            systemImage: "tray",
            description: Text("Add your first product to get started")
        )
    }
    
    @ToolbarContentBuilder
    var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                isShowingAddSheet = true
            } label: {
                Image(systemName: "plus")
            }
            .accessibilityLabel("Add product")
        }
    }
}

// MARK: - Product Row Component

struct ProductRow: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 12) {
            productImage
            productInfo
            Spacer()
            priceLabel
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(product.name), \(product.formattedPrice)")
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
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.name)
                .font(.headline)
            Text(product.category)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var priceLabel: some View {
        Text(product.formattedPrice)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

// MARK: - ViewModel

@MainActor
final class ProductListViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var products: [Product] = []
    @Published private(set) var state: LoadingState = .idle
    @Published var searchText = ""
    
    // MARK: - Dependencies
    private let repository: ProductRepository
    
    // MARK: - Computed
    var filteredProducts: [Product] {
        guard !searchText.isEmpty else { return products }
        return products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.category.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Init
    init(repository: ProductRepository = .shared) {
        self.repository = repository
    }
    
    // MARK: - Actions
    func loadProducts() async {
        guard state != .loading else { return }
        state = .loading
        
        do {
            products = try await repository.fetchProducts()
            state = .loaded
        } catch {
            state = .error(error.localizedDescription)
            Analytics.shared.track(.errorOccurred(
                type: "network",
                message: error.localizedDescription,
                screen: "ProductList"
            ))
        }
    }
    
    func refresh() async {
        do {
            products = try await repository.fetchProducts()
        } catch {
            // Silent fail on refresh, keep existing data
        }
    }
    
    func deleteProducts(at indexSet: IndexSet) async {
        let productsToDelete = indexSet.map { filteredProducts[$0] }
        
        for product in productsToDelete {
            do {
                try await repository.deleteProduct(product)
                products.removeAll { $0.id == product.id }
                Analytics.shared.track(.featureUsed(
                    name: "delete_product",
                    metadata: ["product_id": product.id]
                ))
            } catch {
                // Handle error
            }
        }
    }
}

// MARK: - Loading State

enum LoadingState: Equatable {
    case idle
    case loading
    case loaded
    case error(String)
}

// MARK: - Async Content View

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
            ContentUnavailableView(
                "Something went wrong",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        }
    }
}

// MARK: - Supporting Types

struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let price: Decimal
    let imageURL: URL?
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter.string(from: price as NSDecimalNumber) ?? "$0.00"
    }
}

// Placeholder types for compilation
struct AddProductView: View { var body: some View { Text("Add") } }
struct ProductDetailView: View { let product: Product; var body: some View { Text(product.name) } }
class ProductRepository { static let shared = ProductRepository(); func fetchProducts() async throws -> [Product] { [] }; func deleteProduct(_ p: Product) async throws {} }

// MARK: - Preview

#Preview {
    NavigationStack {
        ProductListView()
    }
}

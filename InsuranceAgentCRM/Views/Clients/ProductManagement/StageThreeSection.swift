import SwiftUI
import CoreData

// MARK: - Stage Three: Product Pairing
struct StageThreeSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var viewModel = ProductPairingViewModel()
    @StateObject private var productEditManager: ProductEditSheetManager
    
    init(client: Client, isEditMode: Bool) {
        self.client = client
        self.isEditMode = isEditMode
        self._productEditManager = StateObject(wrappedValue: ProductEditSheetManager(context: PersistenceController.shared.container.viewContext))
    }
    
    private let productCategories = [
        "Investment", "Medical", "Critical Illness", "Life", "General Insurance", "Savings"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Stage Three: Product Pairing")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if isEditMode {
                    Button("Add Product") {
                        viewModel.showingAddProduct = true
                        viewModel.selectedCategory = ""
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            if viewModel.products.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No Products Added")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if isEditMode {
                        Text("Tap 'Add Product' to start adding insurance products for this client")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.groupedProducts.keys.sorted(), id: \.self) { category in
                        if let products = viewModel.groupedProducts[category], !products.isEmpty {
                            ProductCategoryView(
                                category: category,
                                products: products,
                                isEditMode: isEditMode,
                                onAddProduct: {
                                    viewModel.showingAddProduct = true
                                    viewModel.selectedCategory = category
                                },
                                onDeleteProduct: { product in
                                    deleteProduct(product)
                                },
                                onEditProduct: { product in
                                    productEditManager.startEdit(for: product)
                                }
                            )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            viewModel.loadData(client: client, context: viewContext)
        }
        .onChange(of: isEditMode) { oldValue, newValue in
            if newValue {
                viewModel.loadData(client: client, context: viewContext)
            }
        }
        .onChange(of: client.id) { _, _ in
            viewModel.loadData(client: client, context: viewContext)
        }
        .sheet(isPresented: $viewModel.showingAddProduct) {
            AddProductSheet(
                client: client,
                category: viewModel.selectedCategory,
                context: viewContext,
                onSave: {
                    viewModel.loadData(client: client, context: viewContext)
                }
            )
        }
        .sheet(isPresented: $productEditManager.showingEditProduct) {
            if let product = productEditManager.selectedProduct {
                EditProductSheet(product: product, onSave: {
                    viewModel.loadData(client: client, context: viewContext)
                    productEditManager.dismissEdit()
                })
            } else {
                ErrorSheet(message: "Product not found", onDismiss: productEditManager.dismissEdit)
            }
        }
    }
    
    private func deleteProduct(_ product: ClientProduct) {
        // Delete from Firebase first
        firebaseManager.deleteProduct(product)
        
        // Then delete from Core Data
        viewContext.delete(product)
        do {
            try viewContext.save()
            viewModel.loadData(client: client, context: viewContext)
        } catch {
            print("Error deleting product: \(error)")
        }
    }
    
    
}

// MARK: - Product Category View
struct ProductCategoryView: View {
    let category: String
    let products: [ClientProduct]
    let isEditMode: Bool
    let onAddProduct: () -> Void
    let onDeleteProduct: (ClientProduct) -> Void
    let onEditProduct: (ClientProduct) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    // Category color indicator
                    Circle()
                        .fill(categoryColor)
                        .frame(width: 12, height: 12)
                    
                    Text(category)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(categoryColor)
                }
                
                Spacer()
                Text("\(products.count) product\(products.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ForEach(products) { product in
                ProductCardView(
                    product: product,
                    isEditMode: isEditMode,
                    onDelete: { onDeleteProduct(product) },
                    onEdit: { onEditProduct(product) }
                )
            }
        }
    }
    
    private var categoryColor: Color {
        Color.categoryColor(for: category)
    }
}

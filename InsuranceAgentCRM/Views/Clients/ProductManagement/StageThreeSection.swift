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
            Text("Stage Three: Product Pairing")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isEditMode {
                VStack(spacing: 12) {
                    ForEach(productCategories, id: \.self) { category in
                        ProductCategoryView(
                            category: category,
                            products: viewModel.products.filter { $0.category == category },
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
            } else {
                VStack(spacing: 12) {
                    ForEach(productCategories, id: \.self) { category in
                        ProductCategoryView(
                            category: category,
                            products: viewModel.products.filter { $0.category == category },
                            isEditMode: isEditMode,
                            onAddProduct: {},
                            onDeleteProduct: { _ in },
                            onEditProduct: { _ in }
                        )
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
                print("🔧 DEBUG: Edit mode activated for Stage Three - reloading data")
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
        viewContext.delete(product)
        do {
            try viewContext.save()
            // Sync client to Firebase after product deletion
            firebaseManager.syncClient(client)
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
                Text(category)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if isEditMode {
                    Button("Add") {
                        onAddProduct()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            if products.isEmpty {
                Text("No \(category.lowercased()) products")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
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
    }
}

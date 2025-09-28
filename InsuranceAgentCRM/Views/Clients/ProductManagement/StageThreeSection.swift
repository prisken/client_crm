import SwiftUI
import CoreData

// MARK: - Stage Three: Product Pairing
struct StageThreeSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ProductPairingViewModel()
    @State private var selectedProduct: ClientProduct?
    @State private var showingEditProduct = false
    
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
                                // Validate product before setting it
                                guard product.managedObjectContext != nil else {
                                    print("Warning: Product context is nil, cannot edit")
                                    return
                                }
                                selectedProduct = product
                                showingEditProduct = true
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
        .sheet(isPresented: $showingEditProduct) {
            if let product = selectedProduct, product.managedObjectContext != nil {
                EditProductSheet(product: product, onSave: {
                    viewModel.loadData(client: client, context: viewContext)
                    showingEditProduct = false
                    selectedProduct = nil
                })
            } else {
                // Fallback view if product is nil or invalid
                NavigationView {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Product Not Available")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("The selected product is no longer available or has been deleted.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Close") {
                            showingEditProduct = false
                            selectedProduct = nil
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .navigationTitle("Error")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                showingEditProduct = false
                                selectedProduct = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func deleteProduct(_ product: ClientProduct) {
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

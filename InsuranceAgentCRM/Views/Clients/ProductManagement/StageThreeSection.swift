import SwiftUI
import CoreData

// MARK: - Stage Three: Product Pairing
struct StageThreeSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ProductPairingViewModel()
    @State private var selectedProductID: UUID?
    @State private var showingEditProduct = false
    @State private var selectedProduct: ClientProduct?
    
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
                                selectedProductID = product.id
                                
                                // Immediately fetch the product to avoid timing issues
                                if let productID = product.id {
                                    selectedProduct = fetchProduct(by: productID)
                                    print("🔧 DEBUG: Immediate fetch result - Product: \(selectedProduct?.name ?? "nil"), Found: \(selectedProduct != nil)")
                                    print("🔧 DEBUG: selectedProduct state after fetch: \(selectedProduct?.name ?? "nil"), context: \(selectedProduct?.managedObjectContext != nil ? "valid" : "nil")")
                                }
                                
                                print("🔧 DEBUG: selectedProductID set to \(product.id?.uuidString ?? "nil"), selectedProduct cached, showingEditProduct = true")
                                print("🔧 DEBUG: About to set showingEditProduct = true, selectedProduct is: \(selectedProduct?.name ?? "nil")")
                                showingEditProduct = true
                                print("🔧 DEBUG: showingEditProduct set to true, selectedProduct is still: \(selectedProduct?.name ?? "nil")")
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
        .onChange(of: selectedProduct) { oldValue, newValue in
            print("🔧 DEBUG: selectedProduct changed from '\(oldValue?.name ?? "nil")' to '\(newValue?.name ?? "nil")'")
        }
        .onChange(of: showingEditProduct) { oldValue, newValue in
            print("🔧 DEBUG: showingEditProduct changed from \(oldValue) to \(newValue)")
            if newValue {
                print("🔧 DEBUG: showingEditProduct = true, selectedProduct is: \(selectedProduct?.name ?? "nil")")
            }
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
            // Force evaluation order to prevent timing issues
            let _ = print("🔧 Sheet presentation - showingEditProduct: \(showingEditProduct)")
            let _ = print("🔧 Sheet presentation - selectedProductID: \(selectedProductID?.uuidString ?? "nil")")
            let _ = print("🔧 Sheet presentation - selectedProduct: \(selectedProduct?.name ?? "nil")")
            let _ = print("🔧 Sheet presentation - selectedProduct context: \(selectedProduct?.managedObjectContext != nil ? "valid" : "nil")")
            let _ = print("🔧 Sheet presentation - selectedProduct is nil: \(selectedProduct == nil)")
            
            if let product = selectedProduct {
                let _ = print("🔧 Sheet presentation - Using selectedProduct: \(product.name ?? "nil")")
                EditProductSheet(product: product, onSave: {
                    viewModel.loadData(client: client, context: viewContext)
                    showingEditProduct = false
                    selectedProductID = nil
                    selectedProduct = nil
                })
            } else {
                // Fallback view if product is nil
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
                            selectedProductID = nil
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
                                selectedProductID = nil
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
    
    // Helper function to fetch fresh product by ID
    private func fetchProduct(by id: UUID) -> ClientProduct? {
        print("🔧 DEBUG: fetchProduct called with ID: \(id.uuidString)")
        let request: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let products = try viewContext.fetch(request)
            print("🔧 DEBUG: CoreData fetch returned \(products.count) products")
            if let product = products.first {
                print("🔧 DEBUG: Found product: \(product.name ?? "nil"), ID: \(product.id?.uuidString ?? "nil")")
            } else {
                print("❌ DEBUG: No product found with ID: \(id.uuidString)")
            }
            return products.first
        } catch {
            print("❌ DEBUG: Error fetching product: \(error)")
            return nil
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

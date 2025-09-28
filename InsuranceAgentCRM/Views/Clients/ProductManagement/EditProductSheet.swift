import SwiftUI
import CoreData

// MARK: - Edit Product Sheet
struct EditProductSheet: View {
    let product: ClientProduct
    let onSave: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var category: String = ""
    @State private var amount: String = ""
    @State private var premium: String = ""
    @State private var coverage: String = ""
    @State private var status: String = ""
    @State private var description: String = ""
    @State private var isDataLoaded: Bool = false
    
    var body: some View {
        Group {
            if !isDataLoaded {
                VStack {
                    ProgressView()
                    Text("Loading product details...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                BaseEditSheet(
                    title: "Edit Product",
                    onSave: {
                        saveProduct()
                    }
                ) {
                    Section("Product Details") {
                        FormTextField(title: "Product Name", text: $name)
                        
                        FormPicker(
                            title: "Category",
                            selection: $category,
                            options: FormConstants.productCategories
                        )
                        
                        FormTextField(
                            title: "Coverage Amount",
                            text: $amount,
                            keyboardType: .decimalPad
                        )
                        
                        FormTextField(
                            title: "Premium Amount",
                            text: $premium,
                            keyboardType: .decimalPad
                        )
                        
                        FormTextEditor(
                            title: "Coverage Details",
                            text: $coverage,
                            lineLimit: 2...4
                        )
                        
                        FormPicker(
                            title: "Status",
                            selection: $status,
                            options: FormConstants.productStatuses
                        )
                        
                        FormTextEditor(
                            title: "Description (Optional)",
                            text: $description
                        )
                    }
                }
            }
        }
        .onAppear {
            // Ensure data is loaded when sheet appears
            DispatchQueue.main.async {
                loadProductData()
            }
        }
        .onChange(of: product.id) { _, _ in
            // Reload data if product changes
            loadProductData()
        }
    }
    
    private func loadProductData() {
        // Ensure we have a valid product
        guard product.managedObjectContext != nil else {
            print("Warning: Product context is nil")
            isDataLoaded = false
            return
        }
        
        // Validate product has required data
        guard product.name != nil else {
            print("Warning: Product name is nil")
            isDataLoaded = false
            return
        }
        
        // Load data from product
        name = product.name ?? ""
        category = product.category ?? ""
        amount = String(product.amount?.doubleValue ?? 0)
        premium = String(product.premium?.doubleValue ?? 0)
        coverage = product.coverage ?? ""
        status = product.status ?? ""
        description = product.assetDescription ?? ""
        
        // Mark data as loaded
        isDataLoaded = true
    }
    
    private func saveProduct() {
        product.name = name
        product.category = category
        product.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        product.premium = NSDecimalNumber(string: premium.isEmpty ? "0" : premium)
        product.coverage = coverage.isEmpty ? nil : coverage
        product.status = status
        product.assetDescription = description.isEmpty ? nil : description
        product.updatedAt = Date()
        
        do {
            try viewContext.save()
            onSave()
        } catch {
            print("Error saving product: \(error)")
        }
    }
}

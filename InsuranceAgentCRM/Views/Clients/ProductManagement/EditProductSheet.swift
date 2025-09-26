import SwiftUI
import CoreData

// MARK: - Edit Product Sheet
struct EditProductSheet: View {
    let product: ClientProduct
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var category: String = ""
    @State private var amount: String = ""
    @State private var premium: String = ""
    @State private var coverage: String = ""
    @State private var status: String = ""
    @State private var description: String = ""
    
    private let categories = [
        "Investment", "Medical", "Critical Illness", "Life", "General Insurance", "Savings"
    ]
    
    private let statuses = [
        "Proposed", "Under Review", "Approved", "Active", "Cancelled", "Expired"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Product Details") {
                    TextField("Product Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    TextField("Coverage Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Premium Amount", text: $premium)
                        .keyboardType(.decimalPad)
                    
                    TextField("Coverage Details", text: $coverage, axis: .vertical)
                        .lineLimit(2...4)
                    
                    Picker("Status", selection: $status) {
                        ForEach(statuses, id: \.self) { stat in
                            Text(stat).tag(stat)
                        }
                    }
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProduct()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || category.isEmpty || amount.isEmpty || premium.isEmpty)
                }
            }
        }
        .onAppear {
            loadProductData()
        }
    }
    
    private func loadProductData() {
        name = product.name ?? ""
        category = product.category ?? ""
        amount = String(product.amount?.doubleValue ?? 0)
        premium = String(product.premium?.doubleValue ?? 0)
        coverage = product.coverage ?? ""
        status = product.status ?? ""
        description = product.assetDescription ?? ""
    }
    
    private func saveProduct() {
        product.name = name
        product.category = category
        product.amount = NSDecimalNumber(string: amount)
        product.premium = NSDecimalNumber(string: premium)
        product.coverage = coverage.isEmpty ? nil : coverage
        product.status = status
        product.assetDescription = description.isEmpty ? nil : description
        product.updatedAt = Date()
        
        do {
            try viewContext.save()
            onSave()
            dismiss()
        } catch {
            print("Error saving product: \(error)")
        }
    }
}

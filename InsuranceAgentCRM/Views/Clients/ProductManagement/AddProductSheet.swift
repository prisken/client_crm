import SwiftUI
import CoreData

// MARK: - Add Product Sheet
struct AddProductSheet: View {
    let client: Client
    let category: String
    let context: NSManagedObjectContext
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var name = ""
    @State private var amount = ""
    @State private var premium = ""
    @State private var coverage = ""
    @State private var status = "Proposed"
    @State private var description = ""
    
    var body: some View {
        NavigationView {
            KeyboardAwareForm {
                Section("Product Details") {
                    TextField("Product Name", text: $name)
                    TextField("Coverage Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Premium", text: $premium)
                        .keyboardType(.decimalPad)
                    TextField("Coverage Details", text: $coverage, axis: .vertical)
                        .lineLimit(2...4)
                    
                    Picker("Status", selection: $status) {
                        ForEach(AppConstants.Form.productStatuses, id: \.self) { statusOption in
                            Text(statusOption).tag(statusOption)
                        }
                    }
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add \(category) Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("🔄 Save Product button tapped")
                        saveProduct()
                    }
                    .disabled(name.isEmpty || amount.isEmpty || premium.isEmpty)
                    .mobileTouchTarget()
                }
            }
        }
    }
    
    private func saveProduct() {
        print("🔄 Starting to save product: \(name)")
        print("🔄 Client: \(client.firstName ?? "nil") \(client.lastName ?? "nil") (ID: \(client.id?.uuidString ?? "nil"))")
        
        guard client.id != nil else {
            print("❌ Error: Client has no ID")
            return
        }
        
        let product = ClientProduct(context: context)
        product.id = UUID()
        product.name = name
        product.category = category
        product.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        product.premium = NSDecimalNumber(string: premium.isEmpty ? "0" : premium)
        product.coverage = coverage.isEmpty ? nil : coverage
        product.assetDescription = description.isEmpty ? nil : description
        product.status = status
        product.createdAt = Date()
        product.updatedAt = Date()
        product.client = client
        
        print("🔄 Product client set: \(product.client?.firstName ?? "nil") \(product.client?.lastName ?? "nil")")
        
        do {
            // Clean up any orphaned entities before saving
            cleanupOrphanedEntities()
            
            try context.save()
            print("✅ Product saved successfully to Core Data")
            
            // Sync product to Firebase
            firebaseManager.syncProduct(product)
            print("✅ Product synced to Firebase")
            
            onSave()
            dismiss()
            print("✅ Product sheet dismissed")
        } catch {
            print("❌ Error saving product: \(error)")
        }
    }
    
    private func cleanupOrphanedEntities() {
        // Delete orphaned ClientProducts
        let productRequest: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
        productRequest.predicate = NSPredicate(format: "client == nil")
        do {
            let orphanedProducts = try context.fetch(productRequest)
            for product in orphanedProducts {
                context.delete(product)
                print("🗑️ Deleted orphaned product: \(product.name ?? "Unknown")")
            }
        } catch {
            print("❌ Error fetching orphaned products: \(error)")
        }
        
        // Delete orphaned Assets
        let assetRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        assetRequest.predicate = NSPredicate(format: "client == nil")
        do {
            let orphanedAssets = try context.fetch(assetRequest)
            for asset in orphanedAssets {
                context.delete(asset)
                print("🗑️ Deleted orphaned asset: \(asset.name ?? "Unknown")")
            }
        } catch {
            print("❌ Error fetching orphaned assets: \(error)")
        }
        
        // Delete orphaned Expenses
        let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        expenseRequest.predicate = NSPredicate(format: "client == nil")
        do {
            let orphanedExpenses = try context.fetch(expenseRequest)
            for expense in orphanedExpenses {
                context.delete(expense)
                print("🗑️ Deleted orphaned expense: \(expense.name ?? "Unknown")")
            }
        } catch {
            print("❌ Error fetching orphaned expenses: \(error)")
        }
        
        // Delete orphaned ClientTasks
        let taskRequest: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "client == nil")
        do {
            let orphanedTasks = try context.fetch(taskRequest)
            for task in orphanedTasks {
                context.delete(task)
                print("🗑️ Deleted orphaned task: \(task.title ?? "Unknown")")
            }
        } catch {
            print("❌ Error fetching orphaned tasks: \(error)")
        }
    }
}

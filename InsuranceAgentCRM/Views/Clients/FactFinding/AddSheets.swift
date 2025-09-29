import SwiftUI
import CoreData

// MARK: - Add Asset Sheet
struct AddAssetSheet: View {
    let client: Client
    let context: NSManagedObjectContext
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var name = ""
    @State private var type = "Investment"
    @State private var amount = ""
    @State private var description = ""
    
    private let assetTypes = FormConstants.assetTypes
    
    var body: some View {
        NavigationView {
            Form {
                Section("Asset Details") {
                    TextField("Asset Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(assetTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("🔄 Save Asset button tapped")
                        saveAsset()
                    }
                    .disabled(name.isEmpty || type.isEmpty || amount.isEmpty)
                    .mobileTouchTarget()
                }
            }
        }
    }
    
    private func saveAsset() {
        print("🔄 Starting to save asset: \(name)")
        print("🔄 Client: \(client.firstName ?? "nil") \(client.lastName ?? "nil") (ID: \(client.id?.uuidString ?? "nil"))")
        
        guard client.id != nil else {
            print("❌ Error: Client has no ID")
            return
        }
        
        let asset = Asset(context: context)
        asset.id = UUID()
        asset.name = name
        asset.type = type
        asset.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        asset.assetDescription = description.isEmpty ? nil : description
        asset.createdAt = Date()
        asset.updatedAt = Date()
        asset.client = client
        
        print("🔄 Asset client set: \(asset.client?.firstName ?? "nil") \(asset.client?.lastName ?? "nil")")
        
        do {
            // Clean up any orphaned entities before saving
            cleanupOrphanedEntities()
            
            try context.save()
            print("✅ Asset saved successfully to Core Data")
            
            // Sync asset to Firebase
            firebaseManager.syncAsset(asset)
            print("✅ Asset synced to Firebase")
            
            onSave()
            dismiss()
            print("✅ Asset sheet dismissed")
        } catch {
            print("❌ Error saving asset: \(error)")
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

// MARK: - Add Expense Sheet
struct AddExpenseSheet: View {
    let client: Client
    let context: NSManagedObjectContext
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var name = ""
    @State private var type = "Fixed"
    @State private var amount = ""
    @State private var frequency = "monthly"
    @State private var description = ""
    
    private let expenseTypes = FormConstants.expenseTypes
    private let frequencies = FormConstants.expenseFrequencies
    
    var body: some View {
        NavigationView {
            Form {
                Section("Expense Details") {
                    TextField("Expense Name", text: $name)
                    Picker("Type", selection: $type) {
                        ForEach(expenseTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq.capitalized).tag(freq)
                        }
                    }
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        print("🔄 Save Expense button tapped")
                        saveExpense()
                    }
                    .disabled(name.isEmpty || type.isEmpty || amount.isEmpty)
                    .mobileTouchTarget()
                }
            }
        }
    }
    
    private func saveExpense() {
        print("🔄 Starting to save expense: \(name)")
        print("🔄 Client: \(client.firstName ?? "nil") \(client.lastName ?? "nil") (ID: \(client.id?.uuidString ?? "nil"))")
        
        guard client.id != nil else {
            print("❌ Error: Client has no ID")
            return
        }
        
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.name = name
        expense.type = type
        expense.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        expense.frequency = frequency
        expense.assetDescription = description.isEmpty ? nil : description
        expense.createdAt = Date()
        expense.updatedAt = Date()
        expense.client = client
        
        print("🔄 Expense client set: \(expense.client?.firstName ?? "nil") \(expense.client?.lastName ?? "nil")")
        
        do {
            // Clean up any orphaned entities before saving
            cleanupOrphanedEntities()
            
            try context.save()
            print("✅ Expense saved successfully to Core Data")
            
            // Sync expense to Firebase
            firebaseManager.syncExpense(expense)
            print("✅ Expense synced to Firebase")
            
            onSave()
            dismiss()
            print("✅ Expense sheet dismissed")
        } catch {
            print("❌ Error saving expense: \(error)")
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

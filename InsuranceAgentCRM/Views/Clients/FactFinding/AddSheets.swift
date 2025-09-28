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
                        saveAsset()
                    }
                    .disabled(name.isEmpty || type.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    private func saveAsset() {
        print("🔍 Saving asset: \(name) - \(type) - \(amount)")
        let asset = Asset(context: context)
        asset.id = UUID()
        asset.name = name
        asset.type = type
        asset.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        asset.assetDescription = description.isEmpty ? nil : description
        asset.createdAt = Date()
        asset.updatedAt = Date()
        asset.client = client
        
        do {
            try context.save()
            print("✅ Asset saved successfully")
            
            // Sync asset to Firebase
            firebaseManager.syncAsset(asset)
            
            onSave()
            dismiss()
        } catch {
            print("❌ Error saving asset: \(error)")
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
                        saveExpense()
                    }
                    .disabled(name.isEmpty || type.isEmpty || amount.isEmpty)
                }
            }
        }
    }
    
    private func saveExpense() {
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
        
        do {
            try context.save()
            
            // Sync expense to Firebase
            firebaseManager.syncExpense(expense)
            
            onSave()
            dismiss()
        } catch {
            print("Error saving expense: \(error)")
        }
    }
}

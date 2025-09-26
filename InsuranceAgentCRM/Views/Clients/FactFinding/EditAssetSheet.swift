import SwiftUI
import CoreData

// MARK: - Edit Asset Sheet
struct EditAssetSheet: View {
    let asset: Asset
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var type: String = ""
    @State private var amount: String = ""
    @State private var description: String = ""
    
    private let assetTypes = [
        "Cash", "Savings Account", "Investment", "Property", "Vehicle", 
        "Jewelry", "Art", "Collectibles", "Business", "Other"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Asset Details") {
                    TextField("Asset Name", text: $name)
                    
                    Picker("Asset Type", selection: $type) {
                        ForEach(assetTypes, id: \.self) { assetType in
                            Text(assetType).tag(assetType)
                        }
                    }
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Asset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAsset()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || type.isEmpty || amount.isEmpty)
                }
            }
        }
        .onAppear {
            loadAssetData()
        }
    }
    
    private func loadAssetData() {
        name = asset.name ?? ""
        type = asset.type ?? ""
        amount = String(asset.amount?.doubleValue ?? 0)
        description = asset.assetDescription ?? ""
    }
    
    private func saveAsset() {
        asset.name = name
        asset.type = type
        asset.amount = NSDecimalNumber(string: amount)
        asset.assetDescription = description.isEmpty ? nil : description
        asset.updatedAt = Date()
        
        do {
            try viewContext.save()
            onSave()
            dismiss()
        } catch {
            print("Error saving asset: \(error)")
        }
    }
}

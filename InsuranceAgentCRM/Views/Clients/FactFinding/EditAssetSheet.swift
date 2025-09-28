import SwiftUI
import CoreData

// MARK: - Edit Asset Sheet
struct EditAssetSheet: View {
    let asset: Asset
    let onSave: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var type: String = "Investment"
    @State private var amount: String = ""
    @State private var description: String = ""
    
    
    var body: some View {
        BaseEditSheet(
            title: "Edit Asset",
            onSave: {
                saveAsset()
            }
        ) {
            Section("Asset Details") {
                FormTextField(title: "Asset Name", text: $name)
                
                FormPicker(
                    title: "Asset Type",
                    selection: $type,
                    options: FormConstants.assetTypes
                )
                
                FormTextField(
                    title: "Amount",
                    text: $amount,
                    keyboardType: .decimalPad
                )
                
                FormTextEditor(
                    title: "Description (Optional)",
                    text: $description
                )
            }
        }
        .onAppear {
            // Ensure data is loaded when sheet appears
            DispatchQueue.main.async {
                loadAssetData()
            }
        }
        .onChange(of: asset.id) { _, _ in
            // Reload data if asset changes
            loadAssetData()
        }
    }
    
    private func loadAssetData() {
        // Ensure we have a valid asset
        guard asset.managedObjectContext != nil else {
            print("Warning: Asset context is nil")
            return
        }
        
        name = asset.name ?? ""
        type = asset.type ?? "Investment"
        amount = String(asset.amount?.doubleValue ?? 0)
        description = asset.assetDescription ?? ""
        
    }
    
    private func saveAsset() {
        asset.name = name
        asset.type = type
        asset.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        asset.assetDescription = description.isEmpty ? nil : description
        asset.updatedAt = Date()
        
        do {
            try viewContext.save()
            onSave()
        } catch {
            print("Error saving asset: \(error)")
        }
    }
}

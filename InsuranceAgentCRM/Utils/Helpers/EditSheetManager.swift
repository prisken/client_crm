import SwiftUI
import CoreData

// MARK: - Edit Sheet Manager Protocol
protocol EditSheetManager {
    associatedtype Item: NSManagedObject
    associatedtype EditView: View
    
    func fetchItem(by id: UUID) -> Item?
    func createEditView(for item: Item, onSave: @escaping () -> Void) -> EditView
}

// MARK: - Generic Edit Sheet Manager
class GenericEditSheetManager<Item: NSManagedObject & Identifiable, EditView: View>: ObservableObject, EditSheetManager where Item.ID == UUID {
    @Published var selectedItemID: UUID?
    @Published var showingEditSheet = false
    @Published var selectedItem: Item?
    
    private let context: NSManagedObjectContext
    private let createEditView: (Item, @escaping () -> Void) -> EditView
    
    init(context: NSManagedObjectContext, createEditView: @escaping (Item, @escaping () -> Void) -> EditView) {
        self.context = context
        self.createEditView = createEditView
    }
    
    func startEdit(for item: Item) {
        selectedItemID = item.id
        selectedItem = fetchItem(by: item.id)
        showingEditSheet = true
    }
    
    func fetchItem(by id: UUID) -> Item? {
        let request = NSFetchRequest<Item>(entityName: String(describing: Item.self))
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let items = try context.fetch(request)
            return items.first
        } catch {
            print("❌ Error fetching \(Item.self): \(error)")
            return nil
        }
    }
    
    func createEditView(for item: Item, onSave: @escaping () -> Void) -> EditView {
        return createEditView(item, onSave)
    }
    
    func dismissEdit() {
        showingEditSheet = false
        selectedItemID = nil
        selectedItem = nil
    }
    
    func handleSave() {
        dismissEdit()
    }
}

// MARK: - Asset Edit Sheet Manager
class AssetEditSheetManager: ObservableObject {
    @Published var selectedAssetID: UUID?
    @Published var showingEditAsset = false
    @Published var selectedAsset: Asset?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func startEdit(for asset: Asset) {
        selectedAssetID = asset.id
        selectedAsset = fetchAsset(by: asset.id!)
        showingEditAsset = true
    }
    
    private func fetchAsset(by id: UUID) -> Asset? {
        let request = NSFetchRequest<Asset>(entityName: "Asset")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let assets = try context.fetch(request)
            return assets.first
        } catch {
            print("❌ Error fetching Asset: \(error)")
            return nil
        }
    }
    
    func dismissEdit() {
        showingEditAsset = false
        selectedAssetID = nil
        selectedAsset = nil
    }
}

// MARK: - Expense Edit Sheet Manager
class ExpenseEditSheetManager: ObservableObject {
    @Published var selectedExpenseID: UUID?
    @Published var showingEditExpense = false
    @Published var selectedExpense: Expense?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func startEdit(for expense: Expense) {
        selectedExpenseID = expense.id
        selectedExpense = fetchExpense(by: expense.id!)
        showingEditExpense = true
    }
    
    private func fetchExpense(by id: UUID) -> Expense? {
        let request = NSFetchRequest<Expense>(entityName: "Expense")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let expenses = try context.fetch(request)
            return expenses.first
        } catch {
            print("❌ Error fetching Expense: \(error)")
            return nil
        }
    }
    
    func dismissEdit() {
        showingEditExpense = false
        selectedExpenseID = nil
        selectedExpense = nil
    }
}

// MARK: - Product Edit Sheet Manager
class ProductEditSheetManager: ObservableObject {
    @Published var selectedProductID: UUID?
    @Published var showingEditProduct = false
    @Published var selectedProduct: ClientProduct?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func startEdit(for product: ClientProduct) {
        selectedProductID = product.id
        selectedProduct = fetchProduct(by: product.id!)
        showingEditProduct = true
    }
    
    private func fetchProduct(by id: UUID) -> ClientProduct? {
        let request = NSFetchRequest<ClientProduct>(entityName: "ClientProduct")
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let products = try context.fetch(request)
            return products.first
        } catch {
            print("❌ Error fetching ClientProduct: \(error)")
            return nil
        }
    }
    
    func dismissEdit() {
        showingEditProduct = false
        selectedProductID = nil
        selectedProduct = nil
    }
}

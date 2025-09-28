import SwiftUI
import CoreData
import Combine

// MARK: - Edit Sheet View Model
@MainActor
class EditSheetViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showingError = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
}

// MARK: - Asset Edit View Model
@MainActor
class AssetEditViewModel: EditSheetViewModel {
    @Published var name = ""
    @Published var type = "Investment"
    @Published var amount = ""
    @Published var description = ""
    
    private let asset: Asset
    private let context: NSManagedObjectContext
    
    init(asset: Asset, context: NSManagedObjectContext) {
        self.asset = asset
        self.context = context
        super.init()
        loadData()
    }
    
    func loadData() {
        context.refresh(asset, mergeChanges: true)
        
        name = asset.name ?? ""
        type = asset.type ?? "Investment"
        amount = String(asset.amount?.doubleValue ?? 0)
        description = asset.assetDescription ?? ""
    }
    
    func saveAsset() {
        setLoading(true)
        
        asset.name = name
        asset.type = type
        asset.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        asset.assetDescription = description.isEmpty ? nil : description
        asset.updatedAt = Date()
        
        do {
            try context.save()
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Expense Edit View Model
@MainActor
class ExpenseEditViewModel: EditSheetViewModel {
    @Published var name = ""
    @Published var type = "Fixed"
    @Published var amount = ""
    @Published var frequency = "monthly"
    @Published var description = ""
    
    private let expense: Expense
    private let context: NSManagedObjectContext
    
    init(expense: Expense, context: NSManagedObjectContext) {
        self.expense = expense
        self.context = context
        super.init()
        loadData()
    }
    
    func loadData() {
        context.refresh(expense, mergeChanges: true)
        
        name = expense.name ?? ""
        type = expense.type ?? "Fixed"
        amount = String(expense.amount?.doubleValue ?? 0)
        frequency = expense.frequency ?? "monthly"
        description = expense.assetDescription ?? ""
    }
    
    func saveExpense() {
        setLoading(true)
        
        expense.name = name
        expense.type = type
        expense.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        expense.frequency = frequency
        expense.assetDescription = description.isEmpty ? nil : description
        expense.updatedAt = Date()
        
        do {
            try context.save()
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
}

// MARK: - Product Edit View Model
@MainActor
class ProductEditViewModel: EditSheetViewModel {
    @Published var name = ""
    @Published var category = "Life"
    @Published var amount = ""
    @Published var premium = ""
    @Published var coverage = ""
    @Published var status = "Proposed"
    @Published var description = ""
    
    private let product: ClientProduct
    private let context: NSManagedObjectContext
    
    init(product: ClientProduct, context: NSManagedObjectContext) {
        self.product = product
        self.context = context
        super.init()
        loadData()
    }
    
    func loadData() {
        context.refresh(product, mergeChanges: true)
        
        name = product.name ?? ""
        category = product.category ?? "Life"
        amount = String(product.amount?.doubleValue ?? 0)
        premium = String(product.premium?.doubleValue ?? 0)
        coverage = product.coverage ?? ""
        status = product.status ?? "Proposed"
        description = product.assetDescription ?? ""
    }
    
    func saveProduct() {
        setLoading(true)
        
        product.name = name
        product.category = category
        product.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        product.premium = NSDecimalNumber(string: premium.isEmpty ? "0" : premium)
        product.coverage = coverage.isEmpty ? nil : coverage
        product.status = status
        product.assetDescription = description.isEmpty ? nil : description
        product.updatedAt = Date()
        
        do {
            try context.save()
            setLoading(false)
        } catch {
            handleError(error)
        }
    }
}

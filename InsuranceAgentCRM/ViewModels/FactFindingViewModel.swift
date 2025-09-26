import SwiftUI
import CoreData

class FactFindingViewModel: ObservableObject {
    @Published var assets: [Asset] = []
    @Published var expenses: [Expense] = []
    @Published var showingAddAsset = false
    @Published var showingAddExpense = false
    
    func loadData(client: Client, context: NSManagedObjectContext) {
        print("🔍 Loading fact finding data for: \(client.firstName ?? "") \(client.lastName ?? "")")
        
        // Load assets
        let assetRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        assetRequest.predicate = NSPredicate(format: "client == %@", client)
        assetRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Asset.createdAt, ascending: false)]
        
        do {
            assets = try context.fetch(assetRequest)
            print("🔍 Found \(assets.count) assets")
        } catch {
            print("❌ Error fetching assets: \(error)")
        }
        
        // Load expenses
        let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        expenseRequest.predicate = NSPredicate(format: "client == %@", client)
        expenseRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.createdAt, ascending: false)]
        
        do {
            expenses = try context.fetch(expenseRequest)
            print("🔍 Found \(expenses.count) expenses")
        } catch {
            print("❌ Error fetching expenses: \(error)")
        }
    }
}

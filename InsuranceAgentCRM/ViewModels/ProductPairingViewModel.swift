import SwiftUI
import CoreData

class ProductPairingViewModel: ObservableObject {
    @Published var products: [ClientProduct] = []
    @Published var showingAddProduct = false
    @Published var selectedCategory = ""
    
    // Computed property to group products by category
    var groupedProducts: [String: [ClientProduct]] {
        Dictionary(grouping: products) { $0.category ?? "Uncategorized" }
    }
    
    func loadData(client: Client, context: NSManagedObjectContext) {
        let request: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClientProduct.createdAt, ascending: false)]
        
        do {
            products = try context.fetch(request)
            print("📦 Loaded \(products.count) products for client")
        } catch {
            print("❌ Error fetching products: \(error)")
        }
    }
}

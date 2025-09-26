import SwiftUI
import CoreData

class ProductPairingViewModel: ObservableObject {
    @Published var products: [ClientProduct] = []
    @Published var showingAddProduct = false
    @Published var selectedCategory = ""
    
    func loadData(client: Client, context: NSManagedObjectContext) {
        print("🔍 Loading product pairing data for: \(client.firstName ?? "") \(client.lastName ?? "")")
        let request: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClientProduct.createdAt, ascending: false)]
        
        do {
            products = try context.fetch(request)
            print("🔍 Found \(products.count) products")
        } catch {
            print("❌ Error fetching products: \(error)")
        }
    }
}

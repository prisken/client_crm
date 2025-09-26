import SwiftUI
import CoreData

class ClientsViewModel: ObservableObject {
    @Published var clients: [Client] = []
    var context: NSManagedObjectContext!
    
    func loadClients(context: NSManagedObjectContext, currentUser: User? = nil) {
        self.context = context
        
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        
        // Filter by current user's clients only
        if let user = currentUser {
            request.predicate = NSPredicate(format: "owner == %@", user)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.lastName, ascending: true)]
        
        do {
            clients = try context.fetch(request)
            print("🔍 Loaded \(clients.count) clients for current user")
        } catch {
            print("Error fetching clients: \(error)")
            clients = []
        }
    }
}

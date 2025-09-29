import SwiftUI
import CoreData

class ClientsViewModel: ObservableObject {
    @Published var clients: [Client] = []
    var context: NSManagedObjectContext!
    
    func loadClients(context: NSManagedObjectContext, currentUser: User? = nil) {
        self.context = context
        
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        
        // Debug: Check what users and clients exist
        let allUsersRequest: NSFetchRequest<User> = User.fetchRequest()
        let allClientsRequest: NSFetchRequest<Client> = Client.fetchRequest()
        
        do {
            let allUsers = try context.fetch(allUsersRequest)
            let allClients = try context.fetch(allClientsRequest)
        } catch {
        }
        
        // Filter by current user's clients only
        if let user = currentUser {
            request.predicate = NSPredicate(format: "owner == %@", user)
        } else {
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.lastName, ascending: true)]
        
        do {
            clients = try context.fetch(request)
        } catch {
            print("Error fetching clients: \(error)")
            clients = []
        }
    }
}

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
            print("🔍 Debug - Total users in Core Data: \(allUsers.count)")
            print("🔍 Debug - Total clients in Core Data: \(allClients.count)")
            for user in allUsers {
                print("   - User: \(user.email ?? "no email"), ID: \(user.id?.uuidString ?? "no id")")
            }
            for client in allClients {
                print("   - Client: \(client.firstName ?? "") \(client.lastName ?? ""), Owner: \(client.owner?.email ?? "no owner")")
            }
        } catch {
            print("Error in debug fetch: \(error)")
        }
        
        // Filter by current user's clients only
        if let user = currentUser {
            request.predicate = NSPredicate(format: "owner == %@", user)
            print("🔍 Filtering clients for user: \(user.email ?? "no email"), ID: \(user.id?.uuidString ?? "no id")")
        } else {
            print("⚠️ No current user provided, loading all clients")
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

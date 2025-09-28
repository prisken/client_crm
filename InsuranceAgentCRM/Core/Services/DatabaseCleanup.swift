import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData

@MainActor
class FirebaseCleanupManager: ObservableObject {
    private let db = Firestore.firestore()
    @Published var cleanupStatus = "Ready to cleanup"
    @Published var isCleaning = false
    
    // MARK: - Clean All Firebase Data
    func cleanAllFirebaseData() async {
        guard let currentUser = Auth.auth().currentUser else {
            cleanupStatus = "❌ No authenticated user"
            return
        }
        
        isCleaning = true
        cleanupStatus = "🧹 Starting cleanup..."
        
        do {
            // Clean user-specific collections
            await cleanUserCollections(userId: currentUser.uid)
            
            // Clean old global collections (if they exist)
            await cleanGlobalCollections()
            
            cleanupStatus = "✅ Firebase cleanup completed successfully!"
            
        } catch {
            cleanupStatus = "❌ Cleanup failed: \(error.localizedDescription)"
        }
        
        isCleaning = false
    }
    
    // MARK: - Clean User-Specific Collections
    private func cleanUserCollections(userId: String) async {
        let collections = [
            "clients",
            "assets", 
            "expenses",
            "products",
            "standalone_products",
            "tasks",
            "standalone_tasks"
        ]
        
        for collection in collections {
            do {
                let snapshot = try await db.collection("users")
                    .document(userId)
                    .collection(collection)
                    .getDocuments()
                
                let batch = db.batch()
                for document in snapshot.documents {
                    batch.deleteDocument(document.reference)
                }
                
                if !snapshot.documents.isEmpty {
                    try await batch.commit()
                    print("✅ Cleaned \(snapshot.documents.count) documents from users/\(userId)/\(collection)")
                }
                
            } catch {
                print("❌ Error cleaning \(collection): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Clean Old Global Collections (Legacy)
    private func cleanGlobalCollections() async {
        let globalCollections = [
            "clients",
            "assets",
            "expenses", 
            "products",
            "standalone_products",
            "tasks",
            "standalone_tasks"
        ]
        
        for collection in globalCollections {
            do {
                let snapshot = try await db.collection(collection).getDocuments()
                
                let batch = db.batch()
                for document in snapshot.documents {
                    batch.deleteDocument(document.reference)
                }
                
                if !snapshot.documents.isEmpty {
                    try await batch.commit()
                    print("✅ Cleaned \(snapshot.documents.count) documents from global \(collection)")
                }
                
            } catch {
                print("❌ Error cleaning global \(collection): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Clean Core Data (Local)
    func cleanCoreData(context: NSManagedObjectContext) {
        cleanupStatus = "🧹 Cleaning Core Data..."
        
        // Delete all clients
        let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
        if let clients = try? context.fetch(clientRequest) {
            for client in clients {
                context.delete(client)
            }
        }
        
        // Delete all assets
        let assetRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        if let assets = try? context.fetch(assetRequest) {
            for asset in assets {
                context.delete(asset)
            }
        }
        
        // Delete all expenses
        let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        if let expenses = try? context.fetch(expenseRequest) {
            for expense in expenses {
                context.delete(expense)
            }
        }
        
        // Delete all client products
        let clientProductRequest: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
        if let products = try? context.fetch(clientProductRequest) {
            for product in products {
                context.delete(product)
            }
        }
        
        // Delete all standalone products
        let productRequest: NSFetchRequest<Product> = Product.fetchRequest()
        if let products = try? context.fetch(productRequest) {
            for product in products {
                context.delete(product)
            }
        }
        
        // Delete all client tasks
        let clientTaskRequest: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        if let tasks = try? context.fetch(clientTaskRequest) {
            for task in tasks {
                context.delete(task)
            }
        }
        
        // Delete all standalone tasks
        let taskRequest: NSFetchRequest<Task> = Task.fetchRequest()
        if let tasks = try? context.fetch(taskRequest) {
            for task in tasks {
                context.delete(task)
            }
        }
        
        // Save changes
        do {
            try context.save()
            cleanupStatus = "✅ Core Data cleaned successfully!"
            print("✅ All Core Data entities deleted successfully")
        } catch {
            cleanupStatus = "❌ Core Data cleanup failed: \(error.localizedDescription)"
            print("❌ Error saving Core Data cleanup: \(error)")
        }
    }
}

import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleUser = User(context: viewContext)
        sampleUser.id = UUID()
        sampleUser.email = "agent@example.com"
        sampleUser.role = "agent"
        sampleUser.createdAt = Date()
        sampleUser.updatedAt = Date()
        sampleUser.passwordHash = "hashed_password"
        
        let sampleClient = Client(context: viewContext)
        sampleClient.id = UUID()
        sampleClient.firstName = "John"
        sampleClient.lastName = "Doe"
        sampleClient.phone = "+1234567890"
        sampleClient.email = "john.doe@example.com"
        sampleClient.dob = Calendar.current.date(byAdding: .year, value: -35, to: Date()) ?? Date()
        sampleClient.createdAt = Date()
        sampleClient.updatedAt = Date()
        sampleClient.whatsappOptIn = true
        sampleClient.whatsappOptInDate = Date()
        sampleClient.owner = sampleUser
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "InsuranceAgentCRM")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable CloudKit sync
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

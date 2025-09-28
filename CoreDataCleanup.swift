import Foundation
import CoreData

// MARK: - Core Data Cleanup Helper
// This can be run in Xcode Playground or as a standalone script

func cleanCoreData() {
    // Get the Core Data model URL
    guard let modelURL = Bundle.main.url(forResource: "InsuranceAgentCRM", withExtension: "momd") else {
        print("❌ Could not find Core Data model")
        return
    }
    
    // Create persistent store coordinator
    guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
        print("❌ Could not load Core Data model")
        return
    }
    
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    
    // Get the documents directory
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let storeURL = documentsURL.appendingPathComponent("InsuranceAgentCRM.sqlite")
    
    // Create context
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    
    do {
        // Add persistent store
        _ = try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        
        print("✅ Connected to Core Data store")
        
        // Delete all entities
        let entityNames = ["Client", "Asset", "Expense", "ClientProduct", "Product", "Task", "ClientTask", "User"]
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            try context.execute(deleteRequest)
            print("✅ Cleaned \(entityName) entities")
        }
        
        // Save changes
        try context.save()
        print("✅ Core Data cleanup completed successfully!")
        
    } catch {
        print("❌ Core Data cleanup failed: \(error)")
    }
}

// Uncomment to run cleanup
// cleanCoreData()

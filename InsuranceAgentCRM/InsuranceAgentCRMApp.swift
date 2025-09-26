import SwiftUI
import CoreData

@main
struct InsuranceAgentCRMApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
    
    init() {
        print("🔍 App initialized with persistent store")
        print("🔍 PersistenceController.shared: \(persistenceController)")
        print("🔍 Container: \(persistenceController.container)")
        print("🔍 ViewContext: \(persistenceController.container.viewContext)")
        
        // Force Core Data to initialize
        let _ = persistenceController.container.viewContext
        print("🔍 Core Data initialized successfully")
    }
}


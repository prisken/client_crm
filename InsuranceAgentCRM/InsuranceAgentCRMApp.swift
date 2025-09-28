import SwiftUI
import CoreData

@main
struct InsuranceAgentCRMApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var cloudKitManager = CloudKitManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(cloudKitManager)
        }
    }
    
    init() {
        // Force Core Data to initialize
        let _ = persistenceController.container.viewContext
        
        // Initialize CloudKit manager
        let _ = CloudKitManager.shared
    }
}


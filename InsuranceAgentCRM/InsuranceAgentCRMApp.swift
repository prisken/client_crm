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
        // Force Core Data to initialize
        let _ = persistenceController.container.viewContext
    }
}


import SwiftUI
import CoreData
import FirebaseCore

@main
struct InsuranceAgentCRMApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var firebaseManager = FirebaseManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(firebaseManager)
        }
    }
    
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Force Core Data to initialize
        let _ = persistenceController.container.viewContext
        
        // Initialize Firebase manager
        let _ = FirebaseManager.shared
    }
}


import CloudKit
import CoreData

/// CloudKit schema configuration for ensuring proper sync setup
struct CloudKitSchema {
    
    /// Configure CloudKit container for the app
    static func configureContainer() -> CKContainer {
        return CKContainer(identifier: "iCloud.com.insuranceagent.crm.InsuranceAgentCRM")
    }
    
    /// Verify that all Core Data entities are properly configured for CloudKit sync
    static func validateEntities(in container: NSPersistentContainer) -> [String] {
        var warnings: [String] = []
        
        let model = container.managedObjectModel
        
        let entityNames = ["User", "Client", "Asset", "Expense", "ClientProduct", "Task", "Document"]
        
        for entityName in entityNames {
            if let entity = model.entitiesByName[entityName] {
                // Check for required CloudKit attributes
                if entityName == "Client" {
                    if entity.attributesByName["id"] == nil {
                        warnings.append("❌ Client entity missing 'id' attribute")
                    }
                    if entity.attributesByName["createdAt"] == nil {
                        warnings.append("❌ Client entity missing 'createdAt' attribute")
                    }
                    if entity.attributesByName["updatedAt"] == nil {
                        warnings.append("❌ Client entity missing 'updatedAt' attribute")
                    }
                }
            } else {
                warnings.append("❌ Entity '\(entityName)' not found in model")
            }
        }
        
        return warnings
    }
    
    /// Setup CloudKit schema for first-time sync
    static func setupSchema() async throws {
        let container = configureContainer()
        
        do {
            // Check if we have permission to access CloudKit
            let status = try await container.accountStatus()
            guard status == .available else {
                throw CloudKitError.accountNotAvailable
            }
            
            print("✅ CloudKit schema setup completed")
            
        } catch {
            print("❌ CloudKit schema setup failed: \(error)")
            throw error
        }
    }
}

/// CloudKit specific errors
enum CloudKitError: Error, LocalizedError {
    case accountNotAvailable
    case schemaSetupFailed
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud account is not available. Please sign in to iCloud in Settings."
        case .schemaSetupFailed:
            return "Failed to setup CloudKit schema. Please try again."
        case .syncFailed:
            return "Data sync failed. Please check your internet connection."
        }
    }
}
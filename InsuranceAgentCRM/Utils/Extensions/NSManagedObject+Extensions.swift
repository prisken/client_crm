import CoreData
import Foundation

extension NSManagedObject {
    // MARK: - Safe Property Access
    func safeString(for key: String) -> String {
        value(forKey: key) as? String ?? ""
    }
    
    func safeDate(for key: String) -> Date? {
        value(forKey: key) as? Date
    }
    
    func safeBool(for key: String) -> Bool {
        value(forKey: key) as? Bool ?? false
    }
    
    func safeInt(for key: String) -> Int {
        value(forKey: key) as? Int ?? 0
    }
    
    func safeDouble(for key: String) -> Double {
        value(forKey: key) as? Double ?? 0.0
    }
    
    // MARK: - Safe Property Setting
    func setSafeString(_ value: String?, for key: String) {
        setValue(value, forKey: key)
    }
    
    func setSafeDate(_ value: Date?, for key: String) {
        setValue(value, forKey: key)
    }
    
    func setSafeBool(_ value: Bool, for key: String) {
        setValue(value, forKey: key)
    }
    
    func setSafeInt(_ value: Int, for key: String) {
        setValue(value, forKey: key)
    }
    
    func setSafeDouble(_ value: Double, for key: String) {
        setValue(value, forKey: key)
    }
    
    // MARK: - Timestamp Helpers
    func updateTimestamp() {
        setValue(Date(), forKey: "updatedAt")
    }
    
    func setCreatedTimestamp() {
        if value(forKey: "createdAt") == nil {
            setValue(Date(), forKey: "createdAt")
        }
        updateTimestamp()
    }
    
    // MARK: - Validation
    func isValid() -> Bool {
        do {
            try validateForInsert()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Debugging
    func debugDescription() -> String {
        let entityName = entity.name ?? "Unknown"
        let objectID = objectID.uriRepresentation().absoluteString
        return "\(entityName)(\(objectID))"
    }
}

// MARK: - Batch Operations
extension NSManagedObjectContext {
    func performBatchUpdate<T: NSManagedObject>(
        for entity: T.Type,
        predicate: NSPredicate? = nil,
        update: @escaping (T) -> Void
    ) throws {
        let request = NSFetchRequest<T>(entityName: String(describing: entity))
        request.predicate = predicate
        
        let objects = try fetch(request)
        for object in objects {
            update(object)
        }
        
        try save()
    }
    
    func deleteAll<T: NSManagedObject>(
        for entity: T.Type,
        predicate: NSPredicate? = nil
    ) throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entity))
        request.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try execute(deleteRequest)
    }
}

// MARK: - Fetch Request Helpers
// Note: Generic extensions on NSFetchRequest are not supported due to Objective-C limitations

// MARK: - Core Data Error Handling
extension NSError {
    var isCoreDataError: Bool {
        domain == "NSCocoaErrorDomain"
    }
    
    var coreDataErrorDescription: String {
        switch code {
        case NSValidationErrorMinimum:
            return "Value is too small"
        case NSValidationErrorMaximum:
            return "Value is too large"
        default:
            return localizedDescription
        }
    }
}

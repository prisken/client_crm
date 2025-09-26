import Foundation
import CoreData
import SwiftUI

// MARK: - Data Manager
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    private let context: NSManagedObjectContext
    
    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }
    
    // MARK: - Generic Save
    func save() throws {
        try context.save()
        logInfo("Data saved successfully")
    }
    
    // MARK: - Generic Delete
    func delete<T: NSManagedObject>(_ object: T) throws {
        context.delete(object)
        try save()
        logInfo("Object deleted successfully")
    }
    
    // MARK: - Generic Fetch
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) throws -> [T] {
        return try context.fetch(request)
    }
    
    // MARK: - Client Operations
    func saveClient(_ client: Client) throws {
        client.updatedAt = Date()
        try save()
        logInfo("Client saved: \(client.displayName)")
    }
    
    func deleteClient(_ client: Client) throws {
        try delete(client)
        logInfo("Client deleted: \(client.displayName)")
    }
    
    func fetchClients() throws -> [Client] {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.firstName, ascending: true)]
        return try fetch(request)
    }
    
    // MARK: - Task Operations
    func saveTask(_ task: ClientTask) throws {
        task.updatedAt = Date()
        try save()
        logInfo("Task saved: \(task.title ?? "Unknown")")
    }
    
    func deleteTask(_ task: ClientTask) throws {
        try delete(task)
        logInfo("Task deleted: \(task.title ?? "Unknown")")
    }
    
    func fetchTasks(for client: Client) throws -> [ClientTask] {
        let request: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClientTask.createdAt, ascending: false)]
        return try fetch(request)
    }
    
    // MARK: - Asset Operations
    func saveAsset(_ asset: Asset) throws {
        asset.updatedAt = Date()
        try save()
        logInfo("Asset saved: \(asset.name ?? "Unknown")")
    }
    
    func deleteAsset(_ asset: Asset) throws {
        try delete(asset)
        logInfo("Asset deleted: \(asset.name ?? "Unknown")")
    }
    
    func fetchAssets(for client: Client) throws -> [Asset] {
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Asset.createdAt, ascending: false)]
        return try fetch(request)
    }
    
    // MARK: - Expense Operations
    func saveExpense(_ expense: Expense) throws {
        expense.updatedAt = Date()
        try save()
        logInfo("Expense saved: \(expense.name ?? "Unknown")")
    }
    
    func deleteExpense(_ expense: Expense) throws {
        try delete(expense)
        logInfo("Expense deleted: \(expense.name ?? "Unknown")")
    }
    
    func fetchExpenses(for client: Client) throws -> [Expense] {
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Expense.createdAt, ascending: false)]
        return try fetch(request)
    }
    
    // MARK: - Product Operations
    func saveProduct(_ product: ClientProduct) throws {
        product.updatedAt = Date()
        try save()
        logInfo("Product saved: \(product.name ?? "Unknown")")
    }
    
    func deleteProduct(_ product: ClientProduct) throws {
        try delete(product)
        logInfo("Product deleted: \(product.name ?? "Unknown")")
    }
    
    func fetchProducts(for client: Client) throws -> [ClientProduct] {
        let request: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClientProduct.createdAt, ascending: false)]
        return try fetch(request)
    }
    
    // MARK: - Remark Operations
    func saveRemark(_ remark: TaskRemark) throws {
        remark.updatedAt = Date()
        try save()
        logInfo("Remark saved: \(remark.content ?? "Unknown")")
    }
    
    func deleteRemark(_ remark: TaskRemark) throws {
        try delete(remark)
        logInfo("Remark deleted")
    }
    
    func fetchRemarks(for task: ClientTask) throws -> [TaskRemark] {
        let request: NSFetchRequest<TaskRemark> = TaskRemark.fetchRequest()
        request.predicate = NSPredicate(format: "task == %@", task)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskRemark.createdAt, ascending: false)]
        return try fetch(request)
    }
    
    // MARK: - Batch Operations
    func batchSave() throws {
        try context.save()
        logInfo("Batch save completed")
    }
    
    func rollback() {
        context.rollback()
        logInfo("Changes rolled back")
    }
    
    // MARK: - Context Operations
    func refresh<T: NSManagedObject>(_ object: T) {
        context.refresh(object, mergeChanges: true)
    }
    
    func reset() {
        context.reset()
        logInfo("Context reset")
    }
}

// MARK: - Data Manager Extensions
extension DataManager {
    
    // MARK: - Search Operations
    func searchClients(query: String) throws -> [Client] {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.predicate = NSPredicate(format: 
            "firstName CONTAINS[cd] %@ OR lastName CONTAINS[cd] %@ OR email CONTAINS[cd] %@ OR phone CONTAINS[cd] %@",
            query, query, query, query
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.firstName, ascending: true)]
        return try fetch(request)
    }
    
    // MARK: - Statistics Operations
    func getClientCount() throws -> Int {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        return try context.count(for: request)
    }
    
    func getTaskCount(for client: Client) throws -> Int {
        let request: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@", client)
        return try context.count(for: request)
    }
    
    func getCompletedTaskCount(for client: Client) throws -> Int {
        let request: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        request.predicate = NSPredicate(format: "client == %@ AND isCompleted == YES", client)
        return try context.count(for: request)
    }
}

// MARK: - Data Manager Singleton Access
extension View {
    var dataManager: DataManager {
        return DataManager.shared
    }
}

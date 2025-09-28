import Foundation
import FirebaseCore
import FirebaseFirestore
import SwiftUI
import Combine
import CoreData

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isConnected = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkConnection()
    }
    
    // MARK: - Connection Status
    func checkConnection() {
        // Simple connection test
        db.collection("test").document("connection")
            .getDocument { [weak self] document, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.isConnected = false
                        self?.syncError = "Firebase connection failed: \(error.localizedDescription)"
                        print("❌ Firebase connection failed: \(error)")
                    } else {
                        self?.isConnected = true
                        self?.syncError = nil
                        print("✅ Firebase connected successfully")
                    }
                }
            }
    }
    
    // MARK: - Sync Operations
    func startSync() {
        guard isConnected else {
            syncError = "Firebase not connected"
            return
        }
        
        isSyncing = true
        syncError = nil
        
        // Simulate sync process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
    }
    
    func forceSync() {
        guard isConnected else {
            syncError = "Please check your internet connection"
            return
        }
        
        startSync()
    }
    
    // MARK: - Data Operations
    func syncClient(_ client: Client) {
        guard let clientId = client.id?.uuidString else { return }
        
        let clientData: [String: Any] = [
            "id": clientId,
            "firstName": client.firstName ?? "",
            "lastName": client.lastName ?? "",
            "phone": client.phone ?? "",
            "email": client.email ?? "",
            "address": client.address ?? "",
            "notes": client.notes ?? "",
            "createdAt": client.createdAt ?? Date(),
            "updatedAt": client.updatedAt ?? Date(),
            "interests": client.interests as? [String] ?? [],
            "socialStatus": client.socialStatus as? [String] ?? [],
            "lifeStage": client.lifeStage as? [String] ?? [],
            "whatsappOptIn": client.whatsappOptIn,
            "whatsappOptInDate": client.whatsappOptInDate ?? Date(),
            "ownerId": client.owner?.id?.uuidString ?? ""
        ]
        
        db.collection("clients").document(clientId).setData(clientData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing client: \(error)")
                    self?.syncError = "Failed to sync client: \(error.localizedDescription)"
                } else {
                    print("✅ Client synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncAsset(_ asset: Asset) {
        guard let assetId = asset.id?.uuidString else { return }
        
        let assetData: [String: Any] = [
            "id": assetId,
            "name": asset.name ?? "",
            "type": asset.type ?? "",
            "amount": asset.amount?.doubleValue ?? 0,
            "description": asset.assetDescription ?? "",
            "clientId": asset.client?.id?.uuidString ?? "",
            "createdAt": asset.createdAt ?? Date(),
            "updatedAt": asset.updatedAt ?? Date()
        ]
        
        db.collection("assets").document(assetId).setData(assetData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing asset: \(error)")
                    self?.syncError = "Failed to sync asset: \(error.localizedDescription)"
                } else {
                    print("✅ Asset synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncExpense(_ expense: Expense) {
        guard let expenseId = expense.id?.uuidString else { return }
        
        let expenseData: [String: Any] = [
            "id": expenseId,
            "name": expense.name ?? "",
            "type": expense.type ?? "",
            "amount": expense.amount?.doubleValue ?? 0,
            "frequency": expense.frequency ?? "",
            "description": expense.assetDescription ?? "",
            "clientId": expense.client?.id?.uuidString ?? "",
            "createdAt": expense.createdAt ?? Date(),
            "updatedAt": expense.updatedAt ?? Date()
        ]
        
        db.collection("expenses").document(expenseId).setData(expenseData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing expense: \(error)")
                    self?.syncError = "Failed to sync expense: \(error.localizedDescription)"
                } else {
                    print("✅ Expense synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncProduct(_ product: ClientProduct) {
        guard let productId = product.id?.uuidString else { return }
        
        let productData: [String: Any] = [
            "id": productId,
            "name": product.name ?? "",
            "category": product.category ?? "",
            "amount": product.amount?.doubleValue ?? 0,
            "premium": product.premium?.doubleValue ?? 0,
            "coverage": product.coverage ?? "",
            "status": product.status ?? "",
            "description": product.assetDescription ?? "",
            "clientId": product.client?.id?.uuidString ?? "",
            "createdAt": product.createdAt ?? Date(),
            "updatedAt": product.updatedAt ?? Date()
        ]
        
        db.collection("products").document(productId).setData(productData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing product: \(error)")
                    self?.syncError = "Failed to sync product: \(error.localizedDescription)"
                } else {
                    print("✅ Product synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncStandaloneProduct(_ product: Product) {
        guard let productId = product.id?.uuidString else { return }
        
        var productData: [String: Any] = [
            "id": productId,
            "code": product.code ?? "",
            "name": product.name ?? "",
            "productType": product.productType ?? "",
            "basePremium": product.basePremium?.doubleValue ?? 0,
            "productDescription": product.productDescription ?? "",
            "createdAt": product.createdAt ?? Date(),
            "updatedAt": product.updatedAt ?? Date()
        ]
        
        if let riders = product.riders as? [String] {
            productData["riders"] = riders
        }
        
        db.collection("standalone_products").document(productId).setData(productData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing standalone product: \(error)")
                    self?.syncError = "Failed to sync standalone product: \(error.localizedDescription)"
                } else {
                    print("✅ Standalone product synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncStandaloneTask(_ task: Task) {
        guard let taskId = task.id?.uuidString else { return }
        
        let taskData: [String: Any] = [
            "id": taskId,
            "title": task.title ?? "",
            "notes": task.notes ?? "",
            "dueDate": task.dueDate ?? Date(),
            "priority": task.priority,
            "status": task.status ?? "pending",
            "effortHours": task.effortHours,
            "estimatedCommission": task.estimatedCommission?.doubleValue ?? 0,
            "probability": task.probability,
            "stage": task.stage ?? "",
            "createdAt": task.createdAt ?? Date(),
            "updatedAt": task.updatedAt ?? Date(),
            "clientId": task.client?.id?.uuidString ?? ""
        ]
        
        db.collection("standalone_tasks").document(taskId).setData(taskData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing standalone task: \(error)")
                    self?.syncError = "Failed to sync standalone task: \(error.localizedDescription)"
                } else {
                    print("✅ Standalone task synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncTask(_ task: ClientTask) {
        guard let taskId = task.id?.uuidString else { return }
        
        let taskData: [String: Any] = [
            "id": taskId,
            "title": task.title ?? "",
            "notes": task.notes ?? "",
            "isCompleted": task.isCompleted,
            "createdAt": task.createdAt ?? Date(),
            "updatedAt": task.updatedAt ?? Date(),
            "clientId": task.client?.id?.uuidString ?? ""
        ]
        
        db.collection("tasks").document(taskId).setData(taskData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing task: \(error)")
                    self?.syncError = "Failed to sync task: \(error.localizedDescription)"
                } else {
                    print("✅ Task synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    // MARK: - Fetch Data from Firebase
    func fetchAllData(context: NSManagedObjectContext) {
        guard isConnected else {
            syncError = "Firebase not connected"
            return
        }
        
        isSyncing = true
        
        // Fetch clients from Firebase
        db.collection("clients").getDocuments { [weak self] snapshot, error in
            if let error = error {
                self?.syncError = "Error fetching clients: \(error.localizedDescription)"
                return
            }
            
            guard let documents = snapshot?.documents else {
                self?.syncError = "No client data found"
                return
            }
            
            print("📥 Fetching \(documents.count) clients from Firebase")
            for document in documents {
                let data = document.data()
                self?.createOrUpdateClient(from: data, context: context)
            }
            
            // Fetch assets
            self?.fetchAssets(context: context)
        }
    }
    
    private func fetchAssets(context: NSManagedObjectContext) {
        db.collection("assets").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error fetching assets: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            for document in documents {
                let data = document.data()
                self?.createOrUpdateAsset(from: data, context: context)
            }
            
            // Fetch expenses
            self?.fetchExpenses(context: context)
        }
    }
    
    private func fetchExpenses(context: NSManagedObjectContext) {
        db.collection("expenses").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("❌ Error fetching expenses: \(error)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            for document in documents {
                let data = document.data()
                self?.createOrUpdateExpense(from: data, context: context)
            }
            
            // Fetch products
            self?.fetchProducts(context: context)
        }
    }
    
    private func fetchProducts(context: NSManagedObjectContext) {
        db.collection("products").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isSyncing = false
                if let error = error {
                    print("❌ Error fetching products: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self?.lastSyncDate = Date()
                    print("✅ All data fetched from Firebase")
                    return
                }
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateProduct(from: data, context: context)
                }
                
                self?.lastSyncDate = Date()
                print("✅ All data fetched from Firebase")
            }
        }
    }
    
    // MARK: - Helper Functions for Creating/Updating Entities
    private func createOrUpdateClient(from data: [String: Any], context: NSManagedObjectContext) {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString) else { return }
        
        // Check if client already exists
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let client: Client
        do {
            let existingClients = try context.fetch(request)
            if let existingClient = existingClients.first {
                client = existingClient
            } else {
                client = Client(context: context)
                client.id = id
            }
        } catch {
            client = Client(context: context)
            client.id = id
        }
        
        // Update client data
        client.firstName = data["firstName"] as? String
        client.lastName = data["lastName"] as? String
        client.email = data["email"] as? String
        client.phone = data["phone"] as? String
        client.address = data["address"] as? String
        client.age = data["age"] as? Int16 ?? 0
        client.sex = data["sex"] as? String
        client.notes = data["notes"] as? String
        client.whatsappOptIn = data["whatsappOptIn"] as? Bool ?? false
        client.createdAt = data["createdAt"] as? Date ?? Date()
        client.updatedAt = data["updatedAt"] as? Date ?? Date()
        
        // Handle arrays
        if let interests = data["interests"] as? [String] {
            client.interests = interests as NSObject
        }
        if let socialStatus = data["socialStatus"] as? [String] {
            client.socialStatus = socialStatus as NSObject
        }
        if let lifeStage = data["lifeStage"] as? [String] {
            client.lifeStage = lifeStage as NSObject
        }
        if let tags = data["tags"] as? [String] {
            client.tags = tags as NSObject
        }
        
        // Associate client with the correct user
        if let ownerIdString = data["ownerId"] as? String,
           let ownerId = UUID(uuidString: ownerIdString) {
            // Find the user by ID
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.predicate = NSPredicate(format: "id == %@", ownerId as CVarArg)
            if let user = try? context.fetch(userRequest).first {
                client.owner = user
            }
        } else if client.owner == nil {
            // Fallback: associate with current user if no ownerId in data
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.fetchLimit = 1
            if let currentUser = try? context.fetch(userRequest).first {
                client.owner = currentUser
            }
        }
        
        try? context.save()
        print("✅ Client \(client.firstName ?? "") \(client.lastName ?? "") synced from Firebase with owner: \(client.owner?.email ?? "None")")
    }
    
    private func createOrUpdateAsset(from data: [String: Any], context: NSManagedObjectContext) {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString) else { return }
        
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let asset: Asset
        do {
            let existingAssets = try context.fetch(request)
            if let existingAsset = existingAssets.first {
                asset = existingAsset
            } else {
                asset = Asset(context: context)
                asset.id = id
            }
        } catch {
            asset = Asset(context: context)
            asset.id = id
        }
        
        asset.name = data["name"] as? String
        asset.type = data["type"] as? String
        asset.amount = NSDecimalNumber(value: data["amount"] as? Double ?? 0)
        asset.assetDescription = data["description"] as? String
        asset.createdAt = data["createdAt"] as? Date ?? Date()
        asset.updatedAt = data["updatedAt"] as? Date ?? Date()
        
        // Link to client if clientId exists
        if let clientIdString = data["clientId"] as? String,
           let clientId = UUID(uuidString: clientIdString) {
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            clientRequest.predicate = NSPredicate(format: "id == %@", clientId as CVarArg)
            if let client = try? context.fetch(clientRequest).first {
                asset.client = client
            }
        }
        
        try? context.save()
    }
    
    private func createOrUpdateExpense(from data: [String: Any], context: NSManagedObjectContext) {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString) else { return }
        
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let expense: Expense
        do {
            let existingExpenses = try context.fetch(request)
            if let existingExpense = existingExpenses.first {
                expense = existingExpense
            } else {
                expense = Expense(context: context)
                expense.id = id
            }
        } catch {
            expense = Expense(context: context)
            expense.id = id
        }
        
        expense.name = data["name"] as? String
        expense.type = data["type"] as? String
        expense.amount = NSDecimalNumber(value: data["amount"] as? Double ?? 0)
        expense.frequency = data["frequency"] as? String
        expense.assetDescription = data["description"] as? String
        expense.createdAt = data["createdAt"] as? Date ?? Date()
        expense.updatedAt = data["updatedAt"] as? Date ?? Date()
        
        // Link to client if clientId exists
        if let clientIdString = data["clientId"] as? String,
           let clientId = UUID(uuidString: clientIdString) {
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            clientRequest.predicate = NSPredicate(format: "id == %@", clientId as CVarArg)
            if let client = try? context.fetch(clientRequest).first {
                expense.client = client
            }
        }
        
        try? context.save()
    }
    
    private func createOrUpdateProduct(from data: [String: Any], context: NSManagedObjectContext) {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString) else { return }
        
        let request: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let product: ClientProduct
        do {
            let existingProducts = try context.fetch(request)
            if let existingProduct = existingProducts.first {
                product = existingProduct
            } else {
                product = ClientProduct(context: context)
                product.id = id
            }
        } catch {
            product = ClientProduct(context: context)
            product.id = id
        }
        
        product.name = data["name"] as? String
        product.category = data["category"] as? String
        product.amount = NSDecimalNumber(value: data["amount"] as? Double ?? 0)
        product.premium = NSDecimalNumber(value: data["premium"] as? Double ?? 0)
        product.coverage = data["coverage"] as? String
        product.status = data["status"] as? String
        product.assetDescription = data["description"] as? String
        product.createdAt = data["createdAt"] as? Date ?? Date()
        product.updatedAt = data["updatedAt"] as? Date ?? Date()
        
        // Link to client if clientId exists
        if let clientIdString = data["clientId"] as? String,
           let clientId = UUID(uuidString: clientIdString) {
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            clientRequest.predicate = NSPredicate(format: "id == %@", clientId as CVarArg)
            if let client = try? context.fetch(clientRequest).first {
                product.client = client
            }
        }
        
        try? context.save()
    }
}

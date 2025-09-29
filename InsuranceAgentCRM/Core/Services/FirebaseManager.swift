import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import CoreData

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isConnected = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let db = Firestore.firestore()
    
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
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        db.collection("users").document(currentUserId).collection("clients").document(clientId).setData(clientData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync client: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncAsset(_ asset: Asset) {
        guard let assetId = asset.id?.uuidString,
              let clientId = asset.client?.id?.uuidString else { 
            print("❌ Asset or Client ID not found")
            return 
        }
        
        let assetData: [String: Any] = [
            "id": assetId,
            "name": asset.name ?? "",
            "type": asset.type ?? "",
            "amount": asset.amount?.doubleValue ?? 0,
            "description": asset.assetDescription ?? "",
            "clientId": clientId,
            "createdAt": asset.createdAt ?? Date(),
            "updatedAt": asset.updatedAt ?? Date()
        ]
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        // Save asset to Firebase under client's collection (CORRECT STRUCTURE)
        db.collection("users").document(currentUserId).collection("clients").document(clientId).collection("assets").document(assetId).setData(assetData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync asset: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncExpense(_ expense: Expense) {
        guard let expenseId = expense.id?.uuidString,
              let clientId = expense.client?.id?.uuidString else { 
            print("❌ Expense or Client ID not found")
            return 
        }
        
        let expenseData: [String: Any] = [
            "id": expenseId,
            "name": expense.name ?? "",
            "type": expense.type ?? "",
            "amount": expense.amount?.doubleValue ?? 0,
            "frequency": expense.frequency ?? "",
            "description": expense.assetDescription ?? "",
            "clientId": clientId,
            "createdAt": expense.createdAt ?? Date(),
            "updatedAt": expense.updatedAt ?? Date()
        ]
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        // Save expense to Firebase under client's collection (CORRECT STRUCTURE)
        db.collection("users").document(currentUserId).collection("clients").document(clientId).collection("expenses").document(expenseId).setData(expenseData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync expense: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncProduct(_ product: ClientProduct) {
        guard let productId = product.id?.uuidString,
              let clientId = product.client?.id?.uuidString else { 
            print("❌ Product or Client ID not found")
            return 
        }
        
        let productData: [String: Any] = [
            "id": productId,
            "name": product.name ?? "",
            "category": product.category ?? "",
            "amount": product.amount?.doubleValue ?? 0,
            "premium": product.premium?.doubleValue ?? 0,
            "coverage": product.coverage ?? "",
            "status": product.status ?? "",
            "description": product.assetDescription ?? "",
            "clientId": clientId,
            "createdAt": product.createdAt ?? Date(),
            "updatedAt": product.updatedAt ?? Date()
        ]
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        // Save product to Firebase under client's collection (CORRECT STRUCTURE)
        db.collection("users").document(currentUserId).collection("clients").document(clientId).collection("products").document(productId).setData(productData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync product: \(error.localizedDescription)"
                } else {
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
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        db.collection("users").document(currentUserId).collection("standalone_products").document(productId).setData(productData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync standalone product: \(error.localizedDescription)"
                } else {
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
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        db.collection("users").document(currentUserId).collection("standalone_tasks").document(taskId).setData(taskData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync standalone task: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncTask(_ task: ClientTask) {
        guard let taskId = task.id?.uuidString,
              let clientId = task.client?.id?.uuidString else { 
            print("❌ Task or Client ID not found")
            return 
        }
        
        let taskData: [String: Any] = [
            "id": taskId,
            "title": task.title ?? "",
            "notes": task.notes ?? "",
            "isCompleted": task.isCompleted,
            "createdAt": task.createdAt ?? Date(),
            "updatedAt": task.updatedAt ?? Date(),
            "clientId": clientId
        ]
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        // Save task to Firebase under client's collection (CORRECT STRUCTURE)
        db.collection("users").document(currentUserId).collection("clients").document(clientId).collection("tasks").document(taskId).setData(taskData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync task: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    // MARK: - Delete Data from Firebase
    func deleteClient(_ client: Client) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let clientId = client.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Client ID not found"
            }
            return
        }
        
        // Delete client from Firebase
        db.collection("users").document(currentUser.uid).collection("clients").document(clientId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to delete client from Firebase: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func deleteAsset(_ asset: Asset) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let assetId = asset.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Asset ID not found"
            }
            return
        }
        
        // Delete asset from Firebase
        db.collection("users").document(currentUser.uid).collection("assets").document(assetId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to delete asset from Firebase: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let expenseId = expense.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Expense ID not found"
            }
            return
        }
        
        // Delete expense from Firebase
        db.collection("users").document(currentUser.uid).collection("expenses").document(expenseId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to delete expense from Firebase: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func deleteProduct(_ product: ClientProduct) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let productId = product.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Product ID not found"
            }
            return
        }
        
        // Delete product from Firebase
        db.collection("users").document(currentUser.uid).collection("products").document(productId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to delete product from Firebase: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func deleteTask(_ task: ClientTask) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let taskId = task.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Task ID not found"
            }
            return
        }
        
        // Delete task from Firebase
        db.collection("users").document(currentUser.uid).collection("tasks").document(taskId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to delete task from Firebase: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncRemark(_ remark: TaskRemark) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let remarkId = remark.id?.uuidString,
              let taskId = remark.task?.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Remark or Task ID not found"
            }
            return
        }
        
        let data: [String: Any] = [
            "id": remarkId,
            "content": remark.content ?? "",
            "createdAt": remark.createdAt ?? Date(),
            "updatedAt": remark.updatedAt ?? Date(),
            "taskId": taskId
        ]
        
        // Save remark to Firebase under the task's collection
        db.collection("users").document(currentUser.uid).collection("tasks").document(taskId).collection("remarks").document(remarkId).setData(data) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync remark: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncRelationship(_ relationship: ClientRelationship) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let clientA = relationship.clientA,
              let clientB = relationship.clientB,
              let clientAId = clientA.id?.uuidString,
              let clientBId = clientB.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Relationship or Client ID not found"
            }
            return
        }
        
        guard let relationshipId = relationship.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Relationship ID not found"
            }
            return
        }
        
        let data: [String: Any] = [
            "id": relationshipId,
            "clientAId": clientAId,
            "clientBId": clientBId,
            "relationshipType": relationship.relationshipType ?? "",
            "notes": relationship.notes ?? "",
            "createdAt": relationship.createdAt ?? Date(),
            "updatedAt": relationship.updatedAt ?? Date()
        ]
        
        // Save relationship to Firebase
        db.collection("users").document(currentUser.uid).collection("relationships").document(relationshipId).setData(data) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync relationship: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func loadTagsFromFirebase(completion: @escaping ([String: Any]) -> Void) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            completion([:])
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            completion([:])
            return
        }
        
        // Get all universal tags for the current user
        let tagsRef = db.collection("users").document(currentUser.uid).collection("universal_tags")
        
        tagsRef.getDocuments { [weak self] (querySnapshot, error) in
            if let error = error {
                print("❌ Error loading tags from Firebase: \(error)")
                completion([:])
                return
            }
            
            var tagsByCategory: [String: [String: Any]] = [:]
            
            querySnapshot?.documents.forEach { document in
                let data = document.data()
                if let category = data["category"] as? String,
                   let name = data["name"] as? String {
                    if tagsByCategory[category] == nil {
                        tagsByCategory[category] = [:]
                    }
                    tagsByCategory[category]?[document.documentID] = data
                }
            }
            
            print("📥 Loaded \(querySnapshot?.documents.count ?? 0) universal tags")
            completion(tagsByCategory)
        }
    }
    
    // New method to sync client-specific tag selections
    func syncClientTagSelection(clientId: String, selectedTags: [String], category: String) {
        guard isConnected,
              let currentUser = Auth.auth().currentUser else {
            return
        }
        
        let data: [String: Any] = [
            "tags": selectedTags,
            "category": category,
            "updatedAt": Date()
        ]
        
        // Save client's tag selections
        db.collection("users")
            .document(currentUser.uid)
            .collection("clients")
            .document(clientId)
            .collection("tag_selections")
            .document(category)
            .setData(data) { [weak self] error in
                if let error = error {
                    print("❌ Error syncing client tag selection: \(error)")
                    self?.syncError = "Failed to sync tag selection: \(error.localizedDescription)"
                } else {
                    print("✅ Successfully synced tag selection for client \(clientId)")
                    self?.lastSyncDate = Date()
                }
            }
    }
    
    // New method to load client-specific tag selections
    func loadClientTagSelections(clientId: String, completion: @escaping ([String: [String]]) -> Void) {
        guard isConnected,
              let currentUser = Auth.auth().currentUser else {
            completion([:])
            return
        }
        
        db.collection("users")
            .document(currentUser.uid)
            .collection("clients")
            .document(clientId)
            .collection("tag_selections")
            .getDocuments { (snapshot, error) in
                var selections: [String: [String]] = [:]
                
                if let error = error {
                    print("❌ Error loading client tag selections: \(error)")
                    completion([:])
                    return
                }
                
                snapshot?.documents.forEach { document in
                    let data = document.data()
                    if let category = data["category"] as? String,
                       let tags = data["tags"] as? [String] {
                        selections[category] = tags
                    }
                }
                
                print("📥 Loaded tag selections for client \(clientId)")
                completion(selections)
            }
    }
    
    func syncTag(_ tag: Tag) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let tagId = tag.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Tag ID not found"
            }
            return
        }
        
        let data: [String: Any] = [
            "id": tagId,
            "name": tag.name ?? "",
            "category": tag.category ?? "",
            "createdAt": tag.createdAt ?? Date(),
            "updatedAt": tag.updatedAt ?? Date()
        ]
        
        // Save tag to Firebase under universal_tags
        db.collection("users").document(currentUser.uid).collection("universal_tags").document(tagId).setData(data) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync tag: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func deleteTag(_ tag: Tag) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let tagId = tag.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Tag ID not found"
            }
            return
        }
        
        // Delete tag from Firebase
        db.collection("users").document(currentUser.uid).collection("tags").document(tagId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to delete tag from Firebase: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func deleteRelationship(_ relationship: ClientRelationship) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
            }
            return
        }
        
        guard let currentUser = Auth.auth().currentUser else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user"
            }
            return
        }
        
        guard let relationshipId = relationship.id?.uuidString else {
            DispatchQueue.main.async {
                self.syncError = "Relationship ID not found"
            }
            return
        }
        
        // Delete relationship from Firebase
        db.collection("users").document(currentUser.uid).collection("relationships").document(relationshipId).delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to delete relationship from Firebase: \(error.localizedDescription)"
                } else {
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    // MARK: - Fetch Data from Firebase
    func fetchAllData(context: NSManagedObjectContext) {
        guard isConnected else {
            DispatchQueue.main.async {
                self.syncError = "Firebase not connected"
                self.isSyncing = false
            }
            return
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
            self.syncError = nil
        }
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.syncError = "No authenticated user found"
                self.isSyncing = false
            }
            return
        }
        
        print("🔄 Fetching all data for user: \(currentUserId)")
        
        // Clean up orphaned entities before fetching
        cleanupOrphanedEntities(context: context)
        
        // Fetch clients from Firebase (user-specific collection)
        db.collection("users").document(currentUserId).collection("clients").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Error fetching clients: \(error.localizedDescription)"
                    self?.isSyncing = false
                    print("❌ Error fetching clients: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No client documents found")
                    self?.finishFetch(context: context)
                    return
                }
                
                print("📥 Found \(documents.count) client documents")
                
                // Store client IDs for fetching their associated data
                var clientIds: [String] = []
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateClient(from: data, context: context)
                    
                    // Collect client IDs for fetching associated data
                    if let clientId = data["id"] as? String {
                        clientIds.append(clientId)
                    }
                }
                
                // Save context after clients
                do {
                    try context.save()
                    print("✅ Clients saved to Core Data")
                } catch {
                    print("❌ Error saving clients: \(error.localizedDescription)")
                    if let nsError = error as NSError? {
                        print("❌ Detailed error info:")
                        print("   - Domain: \(nsError.domain)")
                        print("   - Code: \(nsError.code)")
                        print("   - UserInfo: \(nsError.userInfo)")
                        if let validationErrors = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                            for (index, validationError) in validationErrors.enumerated() {
                                print("   - Validation Error \(index + 1): \(validationError.localizedDescription)")
                                print("     Entity: \(validationError.userInfo[NSValidationObjectErrorKey] ?? "Unknown")")
                                print("     Key: \(validationError.userInfo[NSValidationKeyErrorKey] ?? "Unknown")")
                                print("     Value: \(validationError.userInfo[NSValidationValueErrorKey] ?? "Unknown")")
                            }
                        }
                    }
                }
                
                // Fetch associated data for each client
                if !clientIds.isEmpty {
                    self?.fetchClientAssociatedData(clientIds: clientIds, context: context)
                } else {
                    self?.finishFetch(context: context)
                }
            }
        }
    }
    
    private func fetchClientAssociatedData(clientIds: [String], context: NSManagedObjectContext) {
        print("🔄 Fetching associated data for \(clientIds.count) clients")
        
        let dispatchGroup = DispatchGroup()
        var hasErrors = false
        
        // Fetch assets for all clients
        for clientId in clientIds {
            dispatchGroup.enter()
            fetchAssetsForClient(clientId: clientId, context: context) { [weak self] success in
                if !success { hasErrors = true }
                dispatchGroup.leave()
            }
        }
        
        // Fetch expenses for all clients
        for clientId in clientIds {
            dispatchGroup.enter()
            fetchExpensesForClient(clientId: clientId, context: context) { [weak self] success in
                if !success { hasErrors = true }
                dispatchGroup.leave()
            }
        }
        
        // Fetch products for all clients
        for clientId in clientIds {
            dispatchGroup.enter()
            fetchProductsForClient(clientId: clientId, context: context) { [weak self] success in
                if !success { hasErrors = true }
                dispatchGroup.leave()
            }
        }
        
        // Fetch tasks for all clients
        for clientId in clientIds {
            dispatchGroup.enter()
            fetchTasksForClient(clientId: clientId, context: context) { [weak self] success in
                if !success { hasErrors = true }
                dispatchGroup.leave()
            }
        }
        
        // Wait for all fetches to complete
        dispatchGroup.notify(queue: .main) { [weak self] in
            if hasErrors {
                print("⚠️ Some data fetch operations failed")
            } else {
                print("✅ All client associated data fetched successfully")
            }
            self?.finishFetch(context: context)
        }
    }
    
    private func fetchAssetsForClient(clientId: String, context: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection("users").document(currentUserId).collection("clients").document(clientId).collection("assets").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching assets for client \(clientId): \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No asset documents found for client \(clientId)")
                    completion(true)
                    return
                }
                
                print("📥 Found \(documents.count) asset documents for client \(clientId)")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateAsset(from: data, context: context)
                }
                
                // Save context after assets
                do {
                    try context.save()
                    print("✅ Assets saved to Core Data for client \(clientId)")
                } catch {
                    print("❌ Error saving assets for client \(clientId): \(error)")
                    self?.logDetailedError(error)
                }
                
                completion(true)
            }
        }
    }
    
    private func fetchExpensesForClient(clientId: String, context: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection("users").document(currentUserId).collection("clients").document(clientId).collection("expenses").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching expenses for client \(clientId): \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No expense documents found for client \(clientId)")
                    completion(true)
                    return
                }
                
                print("📥 Found \(documents.count) expense documents for client \(clientId)")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateExpense(from: data, context: context)
                }
                
                // Save context after expenses
                do {
                    try context.save()
                    print("✅ Expenses saved to Core Data for client \(clientId)")
                } catch {
                    print("❌ Error saving expenses for client \(clientId): \(error)")
                    self?.logDetailedError(error)
                }
                
                completion(true)
            }
        }
    }
    
    private func fetchProductsForClient(clientId: String, context: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection("users").document(currentUserId).collection("clients").document(clientId).collection("products").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching products for client \(clientId): \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No product documents found for client \(clientId)")
                    completion(true)
                    return
                }
                
                print("📥 Found \(documents.count) product documents for client \(clientId)")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateProduct(from: data, context: context)
                }
                
                // Save context after products
                do {
                    try context.save()
                    print("✅ Products saved to Core Data for client \(clientId)")
                } catch {
                    print("❌ Error saving products for client \(clientId): \(error)")
                    self?.logDetailedError(error)
                }
                
                completion(true)
            }
        }
    }
    
    private func fetchTasksForClient(clientId: String, context: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        db.collection("users").document(currentUserId).collection("clients").document(clientId).collection("tasks").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching tasks for client \(clientId): \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No task documents found for client \(clientId)")
                    completion(true)
                    return
                }
                
                print("📥 Found \(documents.count) task documents for client \(clientId)")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateTask(from: data, context: context)
                }
                
                // Save context after tasks
                do {
                    try context.save()
                    print("✅ Tasks saved to Core Data for client \(clientId)")
                } catch {
                    print("❌ Error saving tasks for client \(clientId): \(error)")
                    self?.logDetailedError(error)
                }
                
                completion(true)
            }
        }
    }
    
    private func fetchAssets(context: NSManagedObjectContext) {
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            DispatchQueue.main.async {
                self.syncError = "No authenticated user found"
                self.isSyncing = false
            }
            return
        }
        
        db.collection("users").document(currentUserId).collection("assets").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching assets: \(error.localizedDescription)")
                    self?.syncError = "Error fetching assets: \(error.localizedDescription)"
                    self?.isSyncing = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No asset documents found")
                    self?.fetchExpenses(context: context)
                    return
                }
                
                print("📥 Found \(documents.count) asset documents")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateAsset(from: data, context: context)
                }
                
                // Save context after assets
                do {
                    try context.save()
                    print("✅ Assets saved to Core Data")
                } catch {
                    print("❌ Error saving assets: \(error.localizedDescription)")
                    self?.logDetailedError(error)
                }
                
                // Fetch expenses
                self?.fetchExpenses(context: context)
            }
        }
    }
    
    private func fetchExpenses(context: NSManagedObjectContext) {
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            DispatchQueue.main.async {
                self.syncError = "No authenticated user found"
                self.isSyncing = false
            }
            return
        }
        
        db.collection("users").document(currentUserId).collection("expenses").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching expenses: \(error.localizedDescription)")
                    self?.syncError = "Error fetching expenses: \(error.localizedDescription)"
                    self?.isSyncing = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No expense documents found")
                    self?.fetchProducts(context: context)
                    return
                }
                
                print("📥 Found \(documents.count) expense documents")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateExpense(from: data, context: context)
                }
                
                // Save context after expenses
                do {
                    try context.save()
                    print("✅ Expenses saved to Core Data")
                } catch {
                    print("❌ Error saving expenses: \(error.localizedDescription)")
                    self?.logDetailedError(error)
                }
                
                // Fetch products
                self?.fetchProducts(context: context)
            }
        }
    }
    
    private func fetchProducts(context: NSManagedObjectContext) {
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            DispatchQueue.main.async {
                self.syncError = "No authenticated user found"
                self.isSyncing = false
            }
            return
        }
        
        db.collection("users").document(currentUserId).collection("products").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching products: \(error.localizedDescription)")
                    self?.syncError = "Error fetching products: \(error.localizedDescription)"
                    self?.isSyncing = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No product documents found")
                    self?.finishFetch(context: context)
                    return
                }
                
                print("📥 Found \(documents.count) product documents")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateProduct(from: data, context: context)
                }
                
                // Save context after products
                do {
                    try context.save()
                    print("✅ Products saved to Core Data")
                } catch {
                    print("❌ Error saving products: \(error.localizedDescription)")
                    self?.logDetailedError(error)
                }
                
                self?.fetchTasks(context: context)
            }
        }
    }
    
    private func fetchTasks(context: NSManagedObjectContext) {
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            DispatchQueue.main.async {
                self.syncError = "No authenticated user found"
                self.isSyncing = false
            }
            return
        }
        
        db.collection("users").document(currentUserId).collection("tasks").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error fetching tasks: \(error.localizedDescription)")
                    self?.syncError = "Error fetching tasks: \(error.localizedDescription)"
                    self?.isSyncing = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No task documents found")
                    self?.finishFetch(context: context)
                    return
                }
                
                print("📥 Found \(documents.count) task documents")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateTask(from: data, context: context)
                }
                
                // Save context after tasks
                do {
                    try context.save()
                    print("✅ Tasks saved to Core Data")
                } catch {
                    print("❌ Error saving tasks: \(error.localizedDescription)")
                    self?.logDetailedError(error)
                }
                
                self?.fetchTags(context: context)
            }
        }
    }
    
    private func fetchTags(context: NSManagedObjectContext) {
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            DispatchQueue.main.async {
                self.syncError = "No authenticated user found"
                self.isSyncing = false
            }
            return
        }
        
        print("🔄 Fetching tags for user: \(currentUserId)")
        
        // Fetch tags from Firebase (user-specific collection)
        db.collection("users").document(currentUserId).collection("tags").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Error fetching tags: \(error.localizedDescription)"
                    self?.isSyncing = false
                    print("❌ Error fetching tags: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No tag documents found")
                    self?.fetchRelationships(context: context)
                    return
                }
                
                print("📥 Found \(documents.count) tag documents")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateTag(from: data, context: context)
                }
                
                // Save tags to Core Data
                do {
                    try context.save()
                    print("✅ Tags saved to Core Data")
                } catch {
                    print("❌ Error saving tags: \(error.localizedDescription)")
                    self?.logDetailedError(error)
                }
                
                self?.fetchRelationships(context: context)
            }
        }
    }
    
    private func fetchRelationships(context: NSManagedObjectContext) {
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            DispatchQueue.main.async {
                self.syncError = "No authenticated user found"
                self.isSyncing = false
            }
            return
        }
        
        print("🔄 Fetching relationships for user: \(currentUserId)")
        
        // Fetch relationships from Firebase (user-specific collection)
        db.collection("users").document(currentUserId).collection("relationships").getDocuments { [weak self] snapshot, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Error fetching relationships: \(error.localizedDescription)"
                    self?.isSyncing = false
                    print("❌ Error fetching relationships: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No relationship documents found")
                    self?.finishFetch(context: context)
                    return
                }
                
                print("📥 Found \(documents.count) relationship documents")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateRelationship(from: data, context: context)
                }
                
                // Save relationships to Core Data
                do {
                    try context.save()
                    print("✅ Relationships saved to Core Data")
                } catch {
                    print("❌ Error saving relationships: \(error.localizedDescription)")
                    self?.logDetailedError(error)
                }
                
                self?.finishFetch(context: context)
            }
        }
    }
    
    private func finishFetch(context: NSManagedObjectContext) {
        // Final save and completion
        do {
            try context.save()
            print("✅ Final context save successful")
        } catch {
            print("❌ Error in final context save: \(error.localizedDescription)")
            logDetailedError(error)
            DispatchQueue.main.async {
                self.syncError = "Error saving data: \(error.localizedDescription)"
            }
        }
        
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
            self.isSyncing = false
        }
        print("✅ All data fetched and saved from Firebase")
    }
    
    private func createOrUpdateTag(from data: [String: Any], context: NSManagedObjectContext) {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString) else { 
            print("❌ Invalid tag ID in data: \(data["id"] ?? "nil")")
            return 
        }
        
        // Check if tag already exists
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let existingTags = try context.fetch(request)
            let tag: Tag
            
            if let existingTag = existingTags.first {
                tag = existingTag
                print("🔄 Updating existing tag: \(tag.name ?? "Unknown")")
            } else {
                tag = Tag(context: context)
                tag.id = id
                print("➕ Creating new tag: \(data["name"] as? String ?? "Unknown")")
            }
            
            // Update tag properties
            tag.name = data["name"] as? String ?? ""
            tag.category = data["category"] as? String ?? ""
            tag.createdAt = data["createdAt"] as? Date ?? Date()
            tag.updatedAt = data["updatedAt"] as? Date ?? Date()
            
            // Set owner (you'll need to get current user)
            // tag.owner = currentUser
            
        } catch {
            print("❌ Error creating/updating tag: \(error.localizedDescription)")
        }
    }
    
    private func createOrUpdateRelationship(from data: [String: Any], context: NSManagedObjectContext) {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString) else { 
            print("❌ Invalid relationship ID in data: \(data["id"] ?? "nil")")
            return 
        }
        
        // Check if relationship already exists
        let request: NSFetchRequest<ClientRelationship> = ClientRelationship.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let existingRelationships = try context.fetch(request)
            let relationship: ClientRelationship
            
            if let existingRelationship = existingRelationships.first {
                relationship = existingRelationship
                print("🔄 Updating existing relationship: \(relationship.relationshipType ?? "Unknown")")
            } else {
                relationship = ClientRelationship(context: context)
                relationship.id = id
                print("➕ Creating new relationship: \(data["relationshipType"] as? String ?? "Unknown")")
            }
            
            // Update relationship properties
            relationship.relationshipType = data["relationshipType"] as? String ?? ""
            relationship.notes = data["notes"] as? String
            relationship.createdAt = data["createdAt"] as? Date ?? Date()
            relationship.updatedAt = data["updatedAt"] as? Date ?? Date()
            relationship.isActive = data["isActive"] as? Bool ?? true
            
            // Set clients (you'll need to find them by ID)
            if let clientAId = data["clientAId"] as? String,
               let clientBId = data["clientBId"] as? String {
                // Find clients by ID
                guard let clientAUUID = UUID(uuidString: clientAId),
                      let clientBUUID = UUID(uuidString: clientBId) else {
                    print("❌ Invalid client IDs: \(clientAId), \(clientBId)")
                    return
                }
                
                let clientARequest: NSFetchRequest<Client> = Client.fetchRequest()
                clientARequest.predicate = NSPredicate(format: "id == %@", clientAUUID as CVarArg)
                
                let clientBRequest: NSFetchRequest<Client> = Client.fetchRequest()
                clientBRequest.predicate = NSPredicate(format: "id == %@", clientBUUID as CVarArg)
                
                do {
                    let clientA = try context.fetch(clientARequest).first
                    let clientB = try context.fetch(clientBRequest).first
                    
                    relationship.clientA = clientA
                    relationship.clientB = clientB
                } catch {
                    print("❌ Error finding clients for relationship: \(error.localizedDescription)")
                }
            }
            
        } catch {
            print("❌ Error creating/updating relationship: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper Functions for Creating/Updating Entities
    private func createOrUpdateClient(from data: [String: Any], context: NSManagedObjectContext) {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString) else { 
            print("❌ Invalid client ID in data: \(data["id"] ?? "nil")")
            return 
        }
        
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
        
        // Handle age conversion carefully
        if let ageValue = data["age"] {
            if let ageInt = ageValue as? Int {
                client.age = Int16(ageInt)
            } else if let ageString = ageValue as? String, let ageInt = Int(ageString) {
                client.age = Int16(ageInt)
            } else {
                client.age = 0
            }
        } else {
            client.age = 0
        }
        
        client.sex = data["sex"] as? String
        client.notes = data["notes"] as? String
        client.whatsappOptIn = data["whatsappOptIn"] as? Bool ?? false
        client.createdAt = data["createdAt"] as? Date ?? Date()
        client.updatedAt = data["updatedAt"] as? Date ?? Date()
        
        // Handle required dob field - set a default date if missing
        if let dobDate = data["dob"] as? Date {
            client.dob = dobDate
        } else {
            // Set a default date of birth (1 year ago) if not provided
            let calendar = Calendar.current
            let defaultDOB = calendar.date(byAdding: .year, value: -30, to: Date()) ?? Date()
            client.dob = defaultDOB
        }
        
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
        
        // Associate client with the current authenticated user (not the ownerId from Firebase)
        // This ensures the client appears for the current user regardless of who originally created it
        if Auth.auth().currentUser?.uid != nil {
            // Find the current user by Firebase UID (stored in email or another field)
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            // Try to find user by email first (most reliable)
            if let currentUserEmail = Auth.auth().currentUser?.email {
                userRequest.predicate = NSPredicate(format: "email == %@", currentUserEmail)
                if let user = try? context.fetch(userRequest).first {
                    client.owner = user
                    print("✅ Client associated with current user: \(user.email ?? "unknown")")
                } else {
                    // Create the current user if not found
                    let newUser = User(context: context)
                    newUser.id = UUID()
                    newUser.email = currentUserEmail
                    newUser.passwordHash = "firebase_user"
                    newUser.role = "agent"
                    newUser.createdAt = Date()
                    newUser.updatedAt = Date()
                    client.owner = newUser
                    print("✅ Created and associated client with new user: \(currentUserEmail)")
                }
            } else {
                // Fallback: use any existing user
                userRequest.fetchLimit = 1
                if let anyUser = try? context.fetch(userRequest).first {
                    client.owner = anyUser
                    print("✅ Client associated with fallback user: \(anyUser.email ?? "unknown")")
                } else {
                    print("❌ No users found in Core Data")
                }
            }
        } else {
            print("❌ No authenticated Firebase user found")
        }
        
        // Context will be saved in batch after all data is fetched
    }
    
    
    // MARK: - Error Logging Helper
    private func logDetailedError(_ error: Error) {
        if let nsError = error as NSError? {
            print("❌ Detailed error info:")
            print("   - Domain: \(nsError.domain)")
            print("   - Code: \(nsError.code)")
            print("   - UserInfo: \(nsError.userInfo)")
            if let validationErrors = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                for (index, validationError) in validationErrors.enumerated() {
                    print("   - Validation Error \(index + 1): \(validationError.localizedDescription)")
                    print("     Entity: \(validationError.userInfo[NSValidationObjectErrorKey] ?? "Unknown")")
                    print("     Key: \(validationError.userInfo[NSValidationKeyErrorKey] ?? "Unknown")")
                    print("     Value: \(validationError.userInfo[NSValidationValueErrorKey] ?? "Unknown")")
                }
            }
        }
    }
    
    // MARK: - Data Migration
    func migrateTagsToNewStructure(completion: @escaping (Bool) -> Void) {
        guard isConnected,
              let currentUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        print("🔄 Starting tag migration to new structure...")
        
        // Step 1: Get all existing tags from old structure
        let oldTagsRef = db.collection("users").document(currentUser.uid).collection("tags")
        
        oldTagsRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching old tags: \(error)")
                completion(false)
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("ℹ️ No tags to migrate")
                completion(true)
                return
            }
            
            print("📥 Found \(documents.count) tags to migrate")
            
            let dispatchGroup = DispatchGroup()
            var migrationSuccess = true
            
            // Step 2: Migrate each tag to universal_tags
            for document in documents {
                dispatchGroup.enter()
                
                let data = document.data()
                let tagId = document.documentID
                
                // Save to new universal_tags collection
                self.db.collection("users")
                    .document(currentUser.uid)
                    .collection("universal_tags")
                    .document(tagId)
                    .setData(data) { error in
                        if let error = error {
                            print("❌ Error migrating tag \(tagId): \(error)")
                            migrationSuccess = false
                        } else {
                            print("✅ Successfully migrated tag \(tagId)")
                            
                            // Delete from old location
                            self.db.collection("users")
                                .document(currentUser.uid)
                                .collection("tags")
                                .document(tagId)
                                .delete { error in
                                    if let error = error {
                                        print("⚠️ Warning: Could not delete old tag \(tagId): \(error)")
                                    }
                                }
                        }
                        dispatchGroup.leave()
                    }
            }
            
            // Step 3: Wait for all operations to complete
            dispatchGroup.notify(queue: .main) {
                print(migrationSuccess ? "✅ Tag migration completed successfully" : "❌ Tag migration completed with errors")
                completion(migrationSuccess)
            }
        }
    }
    
    // MARK: - Create or Update Functions for Client-Specific Data
    private func createOrUpdateAsset(from data: [String: Any], context: NSManagedObjectContext) {
        guard let assetId = data["id"] as? String,
              let clientId = data["clientId"] as? String else {
            print("❌ Missing asset ID or client ID")
            return
        }
        
        // Find existing asset or create new one
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: assetId) ?? UUID()) as CVarArg)
        
        do {
            let existingAssets = try context.fetch(request)
            let asset = existingAssets.first ?? Asset(context: context)
            
            // Set properties
            asset.id = UUID(uuidString: assetId)
            asset.name = data["name"] as? String
            asset.type = data["type"] as? String
            asset.amount = NSDecimalNumber(value: data["amount"] as? Double ?? 0)
            asset.assetDescription = data["description"] as? String
            asset.createdAt = data["createdAt"] as? Date ?? Date()
            asset.updatedAt = data["updatedAt"] as? Date ?? Date()
            
            // Find and set client relationship
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            clientRequest.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: clientId) ?? UUID()) as CVarArg)
            let clients = try context.fetch(clientRequest)
            if let client = clients.first {
                asset.client = client
            }
            
        } catch {
            print("❌ Error creating/updating asset: \(error)")
        }
    }
    
    private func createOrUpdateExpense(from data: [String: Any], context: NSManagedObjectContext) {
        guard let expenseId = data["id"] as? String,
              let clientId = data["clientId"] as? String else {
            print("❌ Missing expense ID or client ID")
            return
        }
        
        // Find existing expense or create new one
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: expenseId) ?? UUID()) as CVarArg)
        
        do {
            let existingExpenses = try context.fetch(request)
            let expense = existingExpenses.first ?? Expense(context: context)
            
            // Set properties
            expense.id = UUID(uuidString: expenseId)
            expense.name = data["name"] as? String
            expense.type = data["type"] as? String
            expense.amount = NSDecimalNumber(value: data["amount"] as? Double ?? 0)
            expense.frequency = data["frequency"] as? String
            expense.assetDescription = data["description"] as? String
            expense.createdAt = data["createdAt"] as? Date ?? Date()
            expense.updatedAt = data["updatedAt"] as? Date ?? Date()
            
            // Find and set client relationship
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            clientRequest.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: clientId) ?? UUID()) as CVarArg)
            let clients = try context.fetch(clientRequest)
            if let client = clients.first {
                expense.client = client
            }
            
        } catch {
            print("❌ Error creating/updating expense: \(error)")
        }
    }
    
    private func createOrUpdateProduct(from data: [String: Any], context: NSManagedObjectContext) {
        guard let productId = data["id"] as? String,
              let clientId = data["clientId"] as? String else {
            print("❌ Missing product ID or client ID")
            return
        }
        
        // Find existing product or create new one
        let request: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: productId) ?? UUID()) as CVarArg)
        
        do {
            let existingProducts = try context.fetch(request)
            let product = existingProducts.first ?? ClientProduct(context: context)
            
            // Set properties
            product.id = UUID(uuidString: productId)
            product.name = data["name"] as? String
            product.category = data["category"] as? String
            product.amount = NSDecimalNumber(value: data["amount"] as? Double ?? 0)
            product.premium = NSDecimalNumber(value: data["premium"] as? Double ?? 0)
            product.coverage = data["coverage"] as? String
            product.status = data["status"] as? String
            product.assetDescription = data["description"] as? String
            product.createdAt = data["createdAt"] as? Date ?? Date()
            product.updatedAt = data["updatedAt"] as? Date ?? Date()
            
            // Find and set client relationship
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            clientRequest.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: clientId) ?? UUID()) as CVarArg)
            let clients = try context.fetch(clientRequest)
            if let client = clients.first {
                product.client = client
            }
            
        } catch {
            print("❌ Error creating/updating product: \(error)")
        }
    }
    
    private func createOrUpdateTask(from data: [String: Any], context: NSManagedObjectContext) {
        guard let taskId = data["id"] as? String,
              let clientId = data["clientId"] as? String else {
            print("❌ Missing task ID or client ID")
            return
        }
        
        // Find existing task or create new one
        let request: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: taskId) ?? UUID()) as CVarArg)
        
        do {
            let existingTasks = try context.fetch(request)
            let task = existingTasks.first ?? ClientTask(context: context)
            
            // Set properties
            task.id = UUID(uuidString: taskId)
            task.title = data["title"] as? String
            task.notes = data["notes"] as? String
            task.isCompleted = data["isCompleted"] as? Bool ?? false
            task.createdAt = data["createdAt"] as? Date ?? Date()
            task.updatedAt = data["updatedAt"] as? Date ?? Date()
            
            // Find and set client relationship
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            clientRequest.predicate = NSPredicate(format: "id == %@", (UUID(uuidString: clientId) ?? UUID()) as CVarArg)
            let clients = try context.fetch(clientRequest)
            if let client = clients.first {
                task.client = client
            }
            
        } catch {
            print("❌ Error creating/updating task: \(error)")
        }
    }
    
    private func cleanupOrphanedEntities(context: NSManagedObjectContext) {
        print("🧹 Cleaning up orphaned entities...")
        
        // Delete orphaned ClientProducts
        let productRequest: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
        productRequest.predicate = NSPredicate(format: "client == nil")
        do {
            let orphanedProducts = try context.fetch(productRequest)
            for product in orphanedProducts {
                context.delete(product)
                print("🗑️ Deleted orphaned product: \(product.name ?? "Unknown")")
            }
        } catch {
            print("❌ Error fetching orphaned products: \(error)")
        }
        
        // Delete orphaned Assets
        let assetRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
        assetRequest.predicate = NSPredicate(format: "client == nil")
        do {
            let orphanedAssets = try context.fetch(assetRequest)
            for asset in orphanedAssets {
                context.delete(asset)
                print("🗑️ Deleted orphaned asset: \(asset.name ?? "Unknown")")
            }
        } catch {
            print("❌ Error fetching orphaned assets: \(error)")
        }
        
        // Delete orphaned Expenses
        let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        expenseRequest.predicate = NSPredicate(format: "client == nil")
        do {
            let orphanedExpenses = try context.fetch(expenseRequest)
            for expense in orphanedExpenses {
                context.delete(expense)
                print("🗑️ Deleted orphaned expense: \(expense.name ?? "Unknown")")
            }
        } catch {
            print("❌ Error fetching orphaned expenses: \(error)")
        }
        
        // Delete orphaned ClientTasks
        let taskRequest: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        taskRequest.predicate = NSPredicate(format: "client == nil")
        do {
            let orphanedTasks = try context.fetch(taskRequest)
            for task in orphanedTasks {
                context.delete(task)
                print("🗑️ Deleted orphaned task: \(task.title ?? "Unknown")")
            }
        } catch {
            print("❌ Error fetching orphaned tasks: \(error)")
        }
        
        // Save the cleanup
        do {
            try context.save()
            print("✅ Orphaned entities cleanup completed")
        } catch {
            print("❌ Error saving cleanup: \(error)")
        }
    }
}

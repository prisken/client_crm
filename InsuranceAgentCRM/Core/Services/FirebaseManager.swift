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
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        db.collection("users").document(currentUserId).collection("assets").document(assetId).setData(assetData) { [weak self] error in
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
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        db.collection("users").document(currentUserId).collection("expenses").document(expenseId).setData(expenseData) { [weak self] error in
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
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        db.collection("users").document(currentUserId).collection("products").document(productId).setData(productData) { [weak self] error in
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
        
        // Get current user ID for user-specific collection
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            print("❌ No authenticated user found")
            return
        }
        
        db.collection("users").document(currentUserId).collection("tasks").document(taskId).setData(taskData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.syncError = "Failed to sync task: \(error.localizedDescription)"
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
                    self?.fetchAssets(context: context)
                    return
                }
                
                print("📥 Found \(documents.count) client documents")
                
                for document in documents {
                    let data = document.data()
                    self?.createOrUpdateClient(from: data, context: context)
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
                
                // Fetch assets
                self?.fetchAssets(context: context)
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
    
    // MARK: - Helper Functions for Creating/Updating Entities
    private func createOrUpdateClient(from data: [String: Any], context: NSManagedObjectContext) {
        print("🔍 Processing client data: \(data.keys.joined(separator: ", "))")
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
                print("⚠️ Invalid age value: \(ageValue), setting to 0")
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
            print("⚠️ Missing dob field, setting default date: \(defaultDOB)")
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
                    print("⚠️ Current user not found in Core Data, creating new user")
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
        
        // Context will be saved in batch after all data is fetched
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
        
        // Context will be saved in batch after all data is fetched
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
        
        // Context will be saved in batch after all data is fetched
    }
    
    private func createOrUpdateTask(from data: [String: Any], context: NSManagedObjectContext) {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString) else { return }
        
        let request: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        let task: ClientTask
        do {
            let existingTasks = try context.fetch(request)
            if let existingTask = existingTasks.first {
                task = existingTask
            } else {
                task = ClientTask(context: context)
                task.id = id
            }
        } catch {
            task = ClientTask(context: context)
            task.id = id
        }
        
        task.title = data["title"] as? String
        task.notes = data["notes"] as? String
        task.isCompleted = data["isCompleted"] as? Bool ?? false
        task.createdAt = data["createdAt"] as? Date ?? Date()
        task.updatedAt = data["updatedAt"] as? Date ?? Date()
        
        // Link to client if clientId exists
        if let clientIdString = data["clientId"] as? String,
           let clientId = UUID(uuidString: clientIdString) {
            let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
            clientRequest.predicate = NSPredicate(format: "id == %@", clientId as CVarArg)
            if let client = try? context.fetch(clientRequest).first {
                task.client = client
            }
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
}

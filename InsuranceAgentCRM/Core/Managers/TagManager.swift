import Foundation
import SwiftUI
import CoreData
import FirebaseAuth
import FirebaseFirestore

// MARK: - Notification Names (moved to AppConstants)
// All notification names are now available through AppConstants.Notifications

// MARK: - Tag Manager
@MainActor
class TagManager: ObservableObject {
    @Published var interestTags: [String] = []
    @Published var socialStatusTags: [String] = []
    @Published var lifeStageTags: [String] = []
    
    private let context: NSManagedObjectContext
    private let firebaseManager: FirebaseManager
    
    // Singleton instance
    static let shared = TagManager(context: PersistenceController.shared.container.viewContext, firebaseManager: FirebaseManager.shared)
    
    init(context: NSManagedObjectContext, firebaseManager: FirebaseManager) {
        self.context = context
        self.firebaseManager = firebaseManager
        migrateIfNeeded()
    }
    
    private func migrateIfNeeded() {
        print("TagManager: Checking if migration is needed...")
        
        // Migrate tags to new structure
        firebaseManager.migrateTagsToNewStructure { [weak self] success in
            if success {
                print("TagManager: Migration completed successfully")
                self?.loadTags() // Load tags after successful migration
            } else {
                print("TagManager: Migration failed, attempting to load tags anyway")
                self?.loadTags()
            }
        }
    }
    
    // MARK: - Load Tags
    @MainActor
    private func loadTags() {
        // First try to load from Firebase and sync to Core Data
        loadTagsFromFirebase()
    }
    
    // MARK: - Public Methods
    @MainActor
    func refreshTags() {
        print("TagManager: Refreshing tags from Firebase...")
        loadTagsFromFirebase()
    }
    
    @MainActor
    private func loadTagsFromFirebase() {
        print("TagManager: Loading tags from Firebase...")
        
        firebaseManager.loadTagsFromFirebase { [weak self] tagsByCategory in
            guard let self = self else { return }
            
            // Process tags by category
            for (category, tags) in tagsByCategory {
                let tagNames = (tags as? [String: [String: Any]])?.values.compactMap { $0["name"] as? String } ?? []
                
                switch category {
                case "Interest":
                    self.interestTags = tagNames
                case "Social Status":
                    self.socialStatusTags = tagNames
                case "Life Stage":
                    self.lifeStageTags = tagNames
                default:
                    print("TagManager: Unknown category: \(category)")
                    break
                }
            }
            
            print("TagManager: Loaded tags from Firebase:")
            print("- Interest tags: \(self.interestTags)")
            print("- Social status tags: \(self.socialStatusTags)")
            print("- Life stage tags: \(self.lifeStageTags)")
            
            // Save tags to Core Data
            self.saveTagsToCore(tagsByCategory)
        }
    }
    
    private func saveTagsToCore(_ tagsByCategory: [String: Any]) {
        guard let currentUser = Auth.auth().currentUser else {
            print("TagManager: No current user found")
            return
        }
        
        // Find the User entity in Core Data using email
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "email == %@", currentUser.email ?? "")
        
        do {
            let users = try context.fetch(userRequest)
            guard let user = users.first else {
                print("TagManager: No user found in Core Data for email: \(currentUser.email ?? "unknown")")
                return
            }
            
            // Process each category
            for (category, tags) in tagsByCategory {
                guard let tagsDict = tags as? [String: [String: Any]] else { continue }
                
                for (tagId, tagData) in tagsDict {
                    guard let name = tagData["name"] as? String else { continue }
                    
                    // Check if tag already exists
                    let request: NSFetchRequest<Tag> = Tag.fetchRequest()
                    request.predicate = NSPredicate(format: "id == %@", tagId)
                    
                    let existingTags = try context.fetch(request)
                    if existingTags.isEmpty {
                        // Create new tag
                        let newTag = Tag(context: context)
                        newTag.id = UUID(uuidString: tagId)
                        newTag.name = name
                        newTag.category = category
                        newTag.owner = user
                        newTag.createdAt = (tagData["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        newTag.updatedAt = (tagData["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                    }
                }
            }
            
            try context.save()
            print("TagManager: Successfully saved Firebase tags to Core Data")
            
        } catch {
            print("TagManager: Error saving tags to Core Data: \(error)")
        }
    }
    
    private func loadTagsFromCoreData() {
        print("TagManager: Loading tags from Core Data...")
        
        // Get current user to filter tags
        guard let currentUser = Auth.auth().currentUser else {
            print("TagManager: No current user found")
            return
        }
        
        // Find the User entity in Core Data using email (same as AuthenticationManager)
        let userRequest: NSFetchRequest<User> = User.fetchRequest()
        userRequest.predicate = NSPredicate(format: "email == %@", currentUser.email ?? "")
        
        do {
            let users = try context.fetch(userRequest)
            guard let user = users.first else {
                print("TagManager: No user found in Core Data for email: \(currentUser.email ?? "unknown")")
                return
            }
            
            // Load interest tags for current user
            let interestRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
            interestRequest.predicate = NSPredicate(format: "category == %@", "Interest")
            interestRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            
            let interestTags = try context.fetch(interestRequest)
            self.interestTags = interestTags.compactMap { $0.name }
            print("TagManager: Loaded interest tags: \(self.interestTags)")
            
            // Load social status tags for current user
            let socialRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
            socialRequest.predicate = NSPredicate(format: "category == %@", "Social Status")
            socialRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            
            let socialTags = try context.fetch(socialRequest)
            self.socialStatusTags = socialTags.compactMap { $0.name }
            print("TagManager: Loaded social status tags: \(self.socialStatusTags)")
            
            // Load life stage tags for current user
            let lifeStageRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
            lifeStageRequest.predicate = NSPredicate(format: "category == %@", "Life Stage")
            lifeStageRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
            
            let lifeStageTags = try context.fetch(lifeStageRequest)
            self.lifeStageTags = lifeStageTags.compactMap { $0.name }
            print("TagManager: Loaded life stage tags: \(self.lifeStageTags)")
            
        } catch {
            print("TagManager: Error loading tags: \(error)")
        }
    }
    
    
    private func syncTagFromFirebase(document: QueryDocumentSnapshot) {
        let data = document.data()
        
        guard let idString = data["id"] as? String,
              let uuid = UUID(uuidString: idString),
              let name = data["name"] as? String,
              let category = data["category"] as? String else {
            print("TagManager: Invalid tag data from Firebase")
            return
        }
        
        // Check if tag already exists in Core Data
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", uuid as CVarArg)
        
        do {
            let existingTags = try context.fetch(request)
            if !existingTags.isEmpty {
                print("TagManager: Tag '\(name)' already exists in Core Data")
                return
            }
            
            // Create new tag in Core Data
            let newTag = Tag(context: context)
            newTag.id = uuid
            newTag.name = name
            newTag.category = category
            
            if let createdAt = data["createdAt"] as? Timestamp {
                newTag.createdAt = createdAt.dateValue()
            } else {
                newTag.createdAt = Date()
            }
            
            if let updatedAt = data["updatedAt"] as? Timestamp {
                newTag.updatedAt = updatedAt.dateValue()
            } else {
                newTag.updatedAt = Date()
            }
            
            // Set owner relationship
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.predicate = NSPredicate(format: "email == %@", Auth.auth().currentUser?.email ?? "")
            
            let users = try context.fetch(userRequest)
            if let user = users.first {
                newTag.owner = user
            }
            
            try context.save()
            print("TagManager: Synced tag '\(name)' from Firebase to Core Data")
            
        } catch {
            print("TagManager: Error syncing tag from Firebase: \(error)")
        }
    }
    
    // MARK: - Save Tags
    private func saveTags() {
        // Save to Core Data and Firebase instead of UserDefaults
        saveTagsToCoreData()
    }
    
    private func saveTagsToCoreData() {
        // This method will be called when tags are added/removed
        // The actual Core Data operations are handled in addTag/removeTag methods
    }
    
    // MARK: - Add Tag
    func addTag(_ tag: String, to category: TagCategory, owner: User) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { 
            print("TagManager: Empty tag text")
            return 
        }
        
        print("TagManager: Starting to add universal tag '\(trimmedTag)' for category '\(category.rawValue)'")
        
        // Check if tag already exists in Core Data
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND category == %@", trimmedTag, category.rawValue)
        
        do {
            let existingTags = try context.fetch(request)
            if !existingTags.isEmpty {
                print("TagManager: Tag '\(trimmedTag)' already exists")
                return // Tag already exists
            }
            
            print("TagManager: Creating new universal tag in Core Data")
            
            // Create new tag in Core Data
            let newTag = Tag(context: context)
            newTag.id = UUID()
            newTag.name = trimmedTag
            newTag.category = category.rawValue
            newTag.createdAt = Date()
            newTag.updatedAt = Date()
            newTag.owner = owner // Set the required owner relationship
            
            print("TagManager: Saving universal tag to Core Data")
            try context.save()
            print("TagManager: Universal tag saved successfully")
            
            // Sync to Firebase as a universal tag
            DispatchQueue.main.async {
                print("TagManager: Syncing universal tag to Firebase")
                self.firebaseManager.syncTag(newTag)
            }
            
            // Update local arrays
            loadTagsFromCoreData()
            objectWillChange.send()
            
        } catch {
            print("TagManager: Error adding universal tag: \(error)")
        }
    }
    
    // MARK: - Client Tag Selection Management
    func updateClientTagSelection(client: Client, selectedTags: [String], category: TagCategory) {
        guard let clientId = client.id?.uuidString else {
            print("TagManager: Client ID not found")
            return
        }
        
        print("TagManager: Updating tag selection for client \(clientId)")
        
        // Update Core Data
        switch category {
        case .interest:
            client.interests = selectedTags as NSObject
        case .socialStatus:
            client.socialStatus = selectedTags as NSObject
        case .lifeStage:
            client.lifeStage = selectedTags as NSObject
        }
        
        do {
            try context.save()
            print("TagManager: Client tag selection saved to Core Data")
            
            // Sync to Firebase
            DispatchQueue.main.async {
                print("TagManager: Syncing client tag selection to Firebase")
                self.firebaseManager.syncClientTagSelection(
                    clientId: clientId,
                    selectedTags: selectedTags,
                    category: category.rawValue
                )
            }
        } catch {
            print("TagManager: Error saving client tag selection: \(error)")
        }
    }
    
    func loadClientTagSelections(client: Client, completion: @escaping () -> Void) {
        guard let clientId = client.id?.uuidString else {
            print("TagManager: Client ID not found")
            completion()
            return
        }
        
        firebaseManager.loadClientTagSelections(clientId: clientId) { [weak self] selections in
            guard let self = self else { return }
            
            // Update Core Data with the selections
            if let interestTags = selections["Interest"] {
                client.interests = interestTags as NSObject
            }
            if let socialStatusTags = selections["Social Status"] {
                client.socialStatus = socialStatusTags as NSObject
            }
            if let lifeStageTags = selections["Life Stage"] {
                client.lifeStage = lifeStageTags as NSObject
            }
            
            do {
                try self.context.save()
                print("TagManager: Client tag selections loaded from Firebase")
            } catch {
                print("TagManager: Error saving loaded tag selections: \(error)")
            }
            
            completion()
        }
    }
    
    // MARK: - Delete Tag
    func deleteTag(_ tag: String, from category: TagCategory) {
        // Find and delete tag from Core Data
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND category == %@", tag, category.rawValue)
        
        do {
            let tags = try context.fetch(request)
            for tagEntity in tags {
                // Sync deletion to Firebase
                DispatchQueue.main.async {
                    self.firebaseManager.deleteTag(tagEntity)
                }
                
                // Delete from Core Data
                context.delete(tagEntity)
            }
            
            try context.save()
            
            // Remove this tag from all clients
            removeTagFromAllClients(tag, category: category)
            
            // Update local arrays
            loadTagsFromCoreData()
            
            // Notify that tags have been updated
            objectWillChange.send()
            
            // Post notification for UI updates
            NotificationCenter.default.post(name: AppConstants.Notifications.tagDeleted, object: (tag: tag, category: category))
            
        } catch {
            print("Error deleting tag: \(error)")
        }
    }
    
    // MARK: - Remove Tag from All Clients
    private func removeTagFromAllClients(_ tag: String, category: TagCategory) {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        
        do {
            let clients = try context.fetch(request)
            for client in clients {
                switch category {
                case .interest:
                    if var interests = client.interests as? [String] {
                        interests.removeAll { $0 == tag }
                        client.interests = interests.isEmpty ? nil : interests as NSObject
                    }
                case .socialStatus:
                    if var socialStatus = client.socialStatus as? [String] {
                        socialStatus.removeAll { $0 == tag }
                        client.socialStatus = socialStatus.isEmpty ? nil : socialStatus as NSObject
                    }
                case .lifeStage:
                    if var lifeStage = client.lifeStage as? [String] {
                        lifeStage.removeAll { $0 == tag }
                        client.lifeStage = lifeStage.isEmpty ? nil : lifeStage as NSObject
                    }
                }
            }
            
            try context.save()
        } catch {
            logError("Error removing tag from clients: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Get Tags for Category
    func getTags(for category: TagCategory) -> [String] {
        switch category {
        case .interest:
            return interestTags
        case .socialStatus:
            return socialStatusTags
        case .lifeStage:
            return lifeStageTags
        }
    }
    
    // MARK: - Debug Functions
    func clearAllTags() {
        interestTags = []
        socialStatusTags = []
        lifeStageTags = []
        saveTags()
    }
    
    func debugPrintTags() {
        // Debug function for development
    }
}

// MARK: - Tag Category
enum TagCategory: String, CaseIterable {
    case interest = "Interest"
    case socialStatus = "Social Status"
    case lifeStage = "Life Stage"
    
    var icon: String {
        switch self {
        case .interest:
            return "heart.fill"
        case .socialStatus:
            return "person.2.fill"
        case .lifeStage:
            return "figure.walk"
        }
    }
    
    var color: Color {
        switch self {
        case .interest:
            return .red
        case .socialStatus:
            return .blue
        case .lifeStage:
            return .green
        }
    }
}

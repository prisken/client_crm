import Foundation
import SwiftUI
import CoreData

// MARK: - Notification Names
extension Notification.Name {
    static let tagDeleted = Notification.Name("tagDeleted")
}

// MARK: - Tag Manager
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
        loadTags()
    }
    
    // MARK: - Load Tags
    private func loadTags() {
        // Load from Core Data instead of UserDefaults
        loadTagsFromCoreData()
    }
    
    private func loadTagsFromCoreData() {
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", "interest")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        do {
            let tags = try context.fetch(request)
            interestTags = tags.compactMap { $0.name }
        } catch {
            print("Error loading interest tags: \(error)")
        }
        
        let socialRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        socialRequest.predicate = NSPredicate(format: "category == %@", "socialStatus")
        socialRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        do {
            let tags = try context.fetch(socialRequest)
            socialStatusTags = tags.compactMap { $0.name }
        } catch {
            print("Error loading social status tags: \(error)")
        }
        
        let lifeStageRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        lifeStageRequest.predicate = NSPredicate(format: "category == %@", "lifeStage")
        lifeStageRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Tag.name, ascending: true)]
        
        do {
            let tags = try context.fetch(lifeStageRequest)
            lifeStageTags = tags.compactMap { $0.name }
        } catch {
            print("Error loading life stage tags: \(error)")
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
    func addTag(_ tag: String, to category: TagCategory) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        
        // Check if tag already exists in Core Data
        let request: NSFetchRequest<Tag> = Tag.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@ AND category == %@", trimmedTag, category.rawValue)
        
        do {
            let existingTags = try context.fetch(request)
            if !existingTags.isEmpty {
                return // Tag already exists
            }
            
            // Create new tag in Core Data
            let newTag = Tag(context: context)
            newTag.id = UUID()
            newTag.name = trimmedTag
            newTag.category = category.rawValue
            newTag.createdAt = Date()
            newTag.updatedAt = Date()
            
            // Set owner (you'll need to get current user)
            // newTag.owner = currentUser
            
            try context.save()
            
            // Sync to Firebase
            DispatchQueue.main.async {
                self.firebaseManager.syncTag(newTag)
            }
            
            // Update local arrays
            loadTagsFromCoreData()
            objectWillChange.send()
            
        } catch {
            print("Error adding tag: \(error)")
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
            NotificationCenter.default.post(name: .tagDeleted, object: (tag: tag, category: category))
            
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

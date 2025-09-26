import Foundation
import SwiftUI
import CoreData

// MARK: - Tag Manager
class TagManager: ObservableObject {
    @Published var interestTags: [String] = []
    @Published var socialStatusTags: [String] = []
    @Published var lifeStageTags: [String] = []
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadTags()
    }
    
    // MARK: - Load Tags
    private func loadTags() {
        // Load from UserDefaults for now (in a real app, you might want to store in Core Data)
        interestTags = UserDefaults.standard.stringArray(forKey: "interestTags") ?? []
        socialStatusTags = UserDefaults.standard.stringArray(forKey: "socialStatusTags") ?? []
        lifeStageTags = UserDefaults.standard.stringArray(forKey: "lifeStageTags") ?? []
        
        print("DEBUG: TagManager loaded tags - Interests: \(interestTags), Social: \(socialStatusTags), Life: \(lifeStageTags)")
    }
    
    // MARK: - Save Tags
    private func saveTags() {
        UserDefaults.standard.set(interestTags, forKey: "interestTags")
        UserDefaults.standard.set(socialStatusTags, forKey: "socialStatusTags")
        UserDefaults.standard.set(lifeStageTags, forKey: "lifeStageTags")
        
        print("DEBUG: TagManager saved tags - Interests: \(interestTags), Social: \(socialStatusTags), Life: \(lifeStageTags)")
    }
    
    // MARK: - Add Tag
    func addTag(_ tag: String, to category: TagCategory) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        
        print("DEBUG: Adding tag '\(trimmedTag)' to category '\(category.rawValue)'")
        
        switch category {
        case .interest:
            if !interestTags.contains(trimmedTag) {
                interestTags.append(trimmedTag)
                print("DEBUG: Added to interests: \(interestTags)")
            }
        case .socialStatus:
            if !socialStatusTags.contains(trimmedTag) {
                socialStatusTags.append(trimmedTag)
                print("DEBUG: Added to social status: \(socialStatusTags)")
            }
        case .lifeStage:
            if !lifeStageTags.contains(trimmedTag) {
                lifeStageTags.append(trimmedTag)
                print("DEBUG: Added to life stage: \(lifeStageTags)")
            }
        }
        
        saveTags()
        objectWillChange.send()
    }
    
    // MARK: - Delete Tag
    func deleteTag(_ tag: String, from category: TagCategory) {
        switch category {
        case .interest:
            interestTags.removeAll { $0 == tag }
        case .socialStatus:
            socialStatusTags.removeAll { $0 == tag }
        case .lifeStage:
            lifeStageTags.removeAll { $0 == tag }
        }
        
        saveTags()
        objectWillChange.send()
        
        // Remove this tag from all clients
        removeTagFromAllClients(tag, category: category)
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
            print("Error removing tag from clients: \(error)")
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
        print("DEBUG: Cleared all tags")
    }
    
    func debugPrintTags() {
        print("DEBUG: Current tags - Interests: \(interestTags), Social: \(socialStatusTags), Life: \(lifeStageTags)")
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

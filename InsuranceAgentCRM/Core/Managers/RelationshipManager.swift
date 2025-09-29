import Foundation
import SwiftUI
import CoreData

// MARK: - Client Relationship Model
struct ClientRelationshipModel: Identifiable {
    let id = UUID()
    let clientA: Client
    let clientB: Client
    let relationshipType: RelationshipOptions.RelationshipType
    let notes: String?
    let createdAt: Date
    var updatedAt: Date
    var isActive: Bool
}

// MARK: - Client Relationship Manager
class RelationshipManager: ObservableObject {
    @Published var relationships: [ClientRelationshipModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let context: NSManagedObjectContext
    private let firebaseManager: FirebaseManager
    
    init(context: NSManagedObjectContext, firebaseManager: FirebaseManager) {
        self.context = context
        self.firebaseManager = firebaseManager
        loadRelationships()
    }
    
    // MARK: - Load Relationships
    private func loadRelationships() {
        // Load relationships from Core Data
        let request: NSFetchRequest<ClientRelationship> = ClientRelationship.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClientRelationship.createdAt, ascending: false)]
        
        do {
            let coreDataRelationships = try context.fetch(request)
            relationships = coreDataRelationships.compactMap { relationship in
                guard let clientA = relationship.clientA,
                      let clientB = relationship.clientB else { return nil }
                
                return ClientRelationshipModel(
                    clientA: clientA,
                    clientB: clientB,
                    relationshipType: RelationshipOptions.RelationshipType(rawValue: relationship.relationshipType ?? "parent") ?? .parent,
                    notes: relationship.notes,
                    createdAt: relationship.createdAt ?? Date(),
                    updatedAt: relationship.updatedAt ?? Date(),
                    isActive: relationship.isActive
                )
            }
        } catch {
            print("Error loading relationships: \(error)")
            relationships = []
        }
    }
    
    // MARK: - Create Relationship
    func createRelationship(
        between clientA: Client,
        and clientB: Client,
        type: RelationshipOptions.RelationshipType,
        notes: String? = nil
    ) {
        // Check if relationship already exists
        if relationshipExists(between: clientA, and: clientB) {
            errorMessage = "A relationship already exists between these clients"
            return
        }
        
        // Check for self-relationship
        if clientA.id == clientB.id {
            errorMessage = "A client cannot have a relationship with themselves"
            return
        }
        
        // Create primary relationship in Core Data
        let relationship = ClientRelationship(context: context)
        relationship.id = UUID()
        relationship.clientA = clientA
        relationship.clientB = clientB
        relationship.relationshipType = type.rawValue
        relationship.notes = notes
        relationship.createdAt = Date()
        relationship.updatedAt = Date()
        relationship.isActive = true
        
        // Create inverse relationship in Core Data
        let inverseRelationship = ClientRelationship(context: context)
        inverseRelationship.id = UUID()
        inverseRelationship.clientA = clientB
        inverseRelationship.clientB = clientA
        inverseRelationship.relationshipType = type.inverseRelationship.rawValue
        inverseRelationship.notes = notes
        inverseRelationship.createdAt = Date()
        inverseRelationship.updatedAt = Date()
        inverseRelationship.isActive = true
        
        do {
            try context.save()
            
            // Sync to Firebase
            DispatchQueue.main.async {
                self.firebaseManager.syncRelationship(relationship)
                self.firebaseManager.syncRelationship(inverseRelationship)
            }
            
            // Update local relationships array
            loadRelationships()
            
            logInfo("Created relationship: \(clientA.displayName) is \(type.rawValue) of \(clientB.displayName)")
            
        } catch {
            print("Error saving relationship: \(error)")
            errorMessage = "Failed to save relationship: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Get Relationships
    func getRelationships(for client: Client) -> [ClientRelationshipModel] {
        return relationships.filter { $0.clientA.id == client.id && $0.isActive }
    }
    
    // MARK: - Get Related Clients
    func getRelatedClients(for client: Client) -> [Client] {
        let clientRelationships = getRelationships(for: client)
        return clientRelationships.map { $0.clientB }
    }
    
    // MARK: - Update Relationship
    func updateRelationship(
        _ relationship: ClientRelationshipModel,
        newType: RelationshipOptions.RelationshipType,
        newNotes: String?
    ) {
        // Find and update both directions
        if let index = relationships.firstIndex(where: { $0.id == relationship.id }) {
            relationships[index] = ClientRelationshipModel(
                clientA: relationship.clientA,
                clientB: relationship.clientB,
                relationshipType: newType,
                notes: newNotes,
                createdAt: relationship.createdAt,
                updatedAt: Date(),
                isActive: relationship.isActive
            )
            
            // Update inverse relationship
            if let inverseIndex = relationships.firstIndex(where: { rel in
                rel.clientA.id == relationship.clientB.id && 
                rel.clientB.id == relationship.clientA.id
            }) {
                relationships[inverseIndex] = ClientRelationshipModel(
                    clientA: relationship.clientB,
                    clientB: relationship.clientA,
                    relationshipType: newType.inverseRelationship,
                    notes: newNotes,
                    createdAt: relationship.createdAt,
                    updatedAt: Date(),
                    isActive: relationship.isActive
                )
            }
        }
        
        saveRelationships()
    }
    
    // MARK: - Delete Relationship
    func deleteRelationship(_ relationship: ClientRelationshipModel) {
        // Find and delete both directions from Core Data
        let request: NSFetchRequest<ClientRelationship> = ClientRelationship.fetchRequest()
        request.predicate = NSPredicate(format: "(clientA == %@ AND clientB == %@) OR (clientA == %@ AND clientB == %@)", 
                                      relationship.clientA, relationship.clientB,
                                      relationship.clientB, relationship.clientA)
        
        do {
            let relationshipsToDelete = try context.fetch(request)
            for rel in relationshipsToDelete {
                // Sync deletion to Firebase
                DispatchQueue.main.async {
                    self.firebaseManager.deleteRelationship(rel)
                }
                
                // Delete from Core Data
                context.delete(rel)
            }
            
            try context.save()
            
            // Update local relationships array
            loadRelationships()
            
            logInfo("Deleted relationship between \(relationship.clientA.displayName) and \(relationship.clientB.displayName)")
            
        } catch {
            print("Error deleting relationship: \(error)")
            errorMessage = "Failed to delete relationship: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Check if Relationship Exists
    private func relationshipExists(between clientA: Client, and clientB: Client) -> Bool {
        return relationships.contains { rel in
            (rel.clientA.id == clientA.id && rel.clientB.id == clientB.id) ||
            (rel.clientA.id == clientB.id && rel.clientB.id == clientA.id)
        }
    }
    
    // MARK: - Get Family Tree
    func getFamilyTree(for client: Client) -> FamilyTree {
        let clientRelationships = getRelationships(for: client)
        return FamilyTree(client: client, relationships: clientRelationships)
    }
    
    // MARK: - Save Relationships
    private func saveRelationships() {
        // Relationships are now saved directly in Core Data in createRelationship method
        // This method is kept for compatibility but no longer needed
        objectWillChange.send()
    }
}

// MARK: - Family Tree Model
struct FamilyTree {
    let client: Client
    let relationships: [ClientRelationshipModel]
    
    var parents: [Client] {
        relationships
            .filter { $0.relationshipType == .parent }
            .map { $0.clientB }
    }
    
    var children: [Client] {
        relationships
            .filter { $0.relationshipType == .child }
            .map { $0.clientB }
    }
    
    var spouse: [Client] {
        relationships
            .filter { $0.relationshipType == .spouse }
            .map { $0.clientB }
    }
    
    var siblings: [Client] {
        relationships
            .filter { $0.relationshipType == .sibling }
            .map { $0.clientB }
    }
    
    var extendedFamily: [Client] {
        relationships
            .filter { $0.relationshipType.category == .extendedFamily }
            .map { $0.clientB }
    }
    
    var businessConnections: [Client] {
        relationships
            .filter { $0.relationshipType.category == .business }
            .map { $0.clientB }
    }
}

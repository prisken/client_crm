import Foundation
import SwiftUI
import CoreData

// MARK: - Client Relationship Model
struct ClientRelationship: Identifiable {
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
    @Published var relationships: [ClientRelationship] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
        loadRelationships()
    }
    
    // MARK: - Load Relationships
    private func loadRelationships() {
        // For now, we'll store relationships as a simple array
        // In a real implementation, you'd store these in Core Data
        relationships = []
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
        
        // Create primary relationship
        let relationship = ClientRelationship(
            clientA: clientA,
            clientB: clientB,
            relationshipType: type,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        )
        
        // Create inverse relationship
        let inverseRelationship = ClientRelationship(
            clientA: clientB,
            clientB: clientA,
            relationshipType: type.inverseRelationship,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date(),
            isActive: true
        )
        
        relationships.append(relationship)
        relationships.append(inverseRelationship)
        
        logInfo("Created relationship: \(clientA.displayName) is \(type.rawValue) of \(clientB.displayName)")
        
        // Save to persistent storage (Core Data)
        saveRelationships()
    }
    
    // MARK: - Get Relationships
    func getRelationships(for client: Client) -> [ClientRelationship] {
        return relationships.filter { $0.clientA.id == client.id && $0.isActive }
    }
    
    // MARK: - Get Related Clients
    func getRelatedClients(for client: Client) -> [Client] {
        let clientRelationships = getRelationships(for: client)
        return clientRelationships.map { $0.clientB }
    }
    
    // MARK: - Update Relationship
    func updateRelationship(
        _ relationship: ClientRelationship,
        newType: RelationshipOptions.RelationshipType,
        newNotes: String?
    ) {
        // Find and update both directions
        if let index = relationships.firstIndex(where: { $0.id == relationship.id }) {
            relationships[index] = ClientRelationship(
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
                relationships[inverseIndex] = ClientRelationship(
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
    func deleteRelationship(_ relationship: ClientRelationship) {
        // Remove both directions
        relationships.removeAll { rel in
            (rel.clientA.id == relationship.clientA.id && rel.clientB.id == relationship.clientB.id) ||
            (rel.clientA.id == relationship.clientB.id && rel.clientB.id == relationship.clientA.id)
        }
        
        logInfo("Deleted relationship between \(relationship.clientA.displayName) and \(relationship.clientB.displayName)")
        saveRelationships()
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
        // For now, we'll just keep them in memory
        // In a real implementation, save to Core Data
        objectWillChange.send()
    }
}

// MARK: - Family Tree Model
struct FamilyTree {
    let client: Client
    let relationships: [ClientRelationship]
    
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

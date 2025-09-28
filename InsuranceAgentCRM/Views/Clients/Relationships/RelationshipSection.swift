import SwiftUI
import CoreData

// MARK: - Relationship Section
struct RelationshipSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var relationshipManager: RelationshipManager
    @State private var showingAddRelationship = false
    @State private var selectedRelationshipID: UUID?
    @State private var showingEditRelationship = false
    @State private var showingFamilyTree = false
    
    init(client: Client, isEditMode: Bool) {
        self.client = client
        self.isEditMode = isEditMode
        self._relationshipManager = StateObject(wrappedValue: RelationshipManager(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            
            if relationshipManager.getRelationships(for: client).isEmpty {
                emptyStateView
            } else {
                relationshipListView
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingAddRelationship) {
            AddRelationshipSheet(
                client: client,
                relationshipManager: relationshipManager
            )
        }
        .sheet(isPresented: $showingEditRelationship) {
            if let relationshipID = selectedRelationshipID,
               let relationship = relationshipManager.getRelationships(for: client).first(where: { $0.id == relationshipID }) {
                EditRelationshipSheet(
                    relationship: relationship,
                    relationshipManager: relationshipManager
                )
            }
        }
        .sheet(isPresented: $showingFamilyTree) {
            FamilyTreeView(
                client: client,
                relationshipManager: relationshipManager
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
                Text("Relationships")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            if isEditMode {
                Button(action: {
                    showingAddRelationship = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if relationshipManager.getRelationships(for: client).count > 0 {
                Button(action: {
                    showingFamilyTree = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "tree")
                        Text("Tree")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Text("\(relationshipManager.getRelationships(for: client).count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No relationships added yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if isEditMode {
                Button("Add First Relationship") {
                    showingAddRelationship = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Relationship List View
    private var relationshipListView: some View {
        VStack(spacing: 8) {
            ForEach(relationshipManager.getRelationships(for: client)) { relationship in
                RelationshipRowView(
                    relationship: relationship,
                    isEditMode: isEditMode,
                    onEdit: {
                        selectedRelationshipID = relationship.id
                        showingEditRelationship = true
                    },
                    onDelete: {
                        relationshipManager.deleteRelationship(relationship)
                    }
                )
            }
        }
    }
}

// MARK: - Relationship Row View
struct RelationshipRowView: View {
    let relationship: ClientRelationship
    let isEditMode: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Relationship Icon
            Image(systemName: relationship.relationshipType.icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            
            // Relationship Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(relationship.clientB.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(relationship.relationshipType.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(relationship.relationshipType.category.color)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
                
                if let notes = relationship.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Text("Added \(relationship.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Edit/Delete Buttons
            if isEditMode {
                VStack(spacing: 8) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .confirmationDialog("Delete Relationship", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete the relationship with \(relationship.clientB.displayName)?")
        }
    }
}

// MARK: - Relationship Category Extension
extension RelationshipOptions.RelationshipCategory {
    var color: Color {
        switch self {
        case .immediateFamily: return .green
        case .family: return .blue
        case .extendedFamily: return .purple
        case .guardianship: return .orange
        case .business: return .brown
        case .other: return .gray
        }
    }
}

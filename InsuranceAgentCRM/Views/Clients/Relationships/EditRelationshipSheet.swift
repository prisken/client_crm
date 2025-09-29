import SwiftUI
import CoreData

// MARK: - Edit Relationship Sheet
struct EditRelationshipSheet: View {
    let relationship: ClientRelationshipModel
    let relationshipManager: RelationshipManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedRelationshipType: RelationshipOptions.RelationshipType
    @State private var notes: String
    
    init(relationship: ClientRelationshipModel, relationshipManager: RelationshipManager) {
        self.relationship = relationship
        self.relationshipManager = relationshipManager
        self._selectedRelationshipType = State(initialValue: relationship.relationshipType)
        self._notes = State(initialValue: relationship.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Relationship Type Selection
                        relationshipTypeSection
                        
                        // Notes Section
                        notesSection
                        
                        // Preview Section
                        previewSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Relationship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Client A
                VStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    Text(relationship.clientA.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 80)
                
                // Arrow
                Image(systemName: "arrow.left.and.right")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Client B
                VStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    Text(relationship.clientB.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 80)
            }
            
            Text("Editing relationship between \(relationship.clientA.displayName) and \(relationship.clientB.displayName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Relationship Type Section
    private var relationshipTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relationship Type")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                ForEach(RelationshipOptions.RelationshipType.allCases) { type in
                    Button(action: {
                        selectedRelationshipType = type
                    }) {
                        HStack {
                            Image(systemName: type.icon)
                                .font(.title3)
                            Text(type.rawValue)
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(selectedRelationshipType == type ? Color.blue : Color(.systemGray6))
                        .foregroundColor(selectedRelationshipType == type ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .fontWeight(.semibold)
            
            TextField("Add notes about this relationship...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Updated Relationship")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Primary:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(relationship.clientA.displayName) is \(selectedRelationshipType.rawValue) of \(relationship.clientB.displayName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Inverse:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(relationship.clientB.displayName) is \(selectedRelationshipType.inverseRelationship.rawValue) of \(relationship.clientA.displayName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            if selectedRelationshipType != relationship.relationshipType {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Changing relationship type will update both directions automatically")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    private func saveChanges() {
        relationshipManager.updateRelationship(
            relationship,
            newType: selectedRelationshipType,
            newNotes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

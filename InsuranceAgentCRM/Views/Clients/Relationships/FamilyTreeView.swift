import SwiftUI
import CoreData

// MARK: - Family Tree View
struct FamilyTreeView: View {
    let client: Client
    let relationshipManager: RelationshipManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var familyTree: FamilyTree
    
    init(client: Client, relationshipManager: RelationshipManager) {
        self.client = client
        self.relationshipManager = relationshipManager
        self._familyTree = State(initialValue: FamilyTree(client: client, relationships: []))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Parents Section
                    if !familyTree.parents.isEmpty {
                        familySection(title: "Parents", 
                                    icon: "person.2.fill", 
                                    color: .blue,
                                    clients: familyTree.parents)
                    }
                    
                    // Spouse Section
                    if !familyTree.spouse.isEmpty {
                        familySection(title: "Spouse", 
                                    icon: "heart.fill", 
                                    color: .red,
                                    clients: familyTree.spouse)
                    }
                    
                    // Central Client
                    centralClientView
                    
                    // Children Section
                    if !familyTree.children.isEmpty {
                        familySection(title: "Children", 
                                    icon: "figure.and.child.holdinghands", 
                                    color: .green,
                                    clients: familyTree.children)
                    }
                    
                    // Siblings Section
                    if !familyTree.siblings.isEmpty {
                        familySection(title: "Siblings", 
                                    icon: "person.3.fill", 
                                    color: .orange,
                                    clients: familyTree.siblings)
                    }
                    
                    // Extended Family Section
                    if !familyTree.extendedFamily.isEmpty {
                        familySection(title: "Extended Family", 
                                    icon: "person.3.sequence.fill", 
                                    color: .purple,
                                    clients: familyTree.extendedFamily)
                    }
                    
                    // Business Connections Section
                    if !familyTree.businessConnections.isEmpty {
                        familySection(title: "Business Connections", 
                                    icon: "briefcase.fill", 
                                    color: .brown,
                                    clients: familyTree.businessConnections)
                    }
                    
                    // Empty State
                    if hasNoRelationships {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("Family Tree")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadFamilyTree()
        }
    }
    
    // MARK: - Central Client View
    private var centralClientView: some View {
        VStack(spacing: 12) {
            // Client Avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // Client Info
            VStack(spacing: 4) {
                Text(client.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Main Client")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
            }
            
            // Relationship Count
            Text("\(relationshipManager.getRelationships(for: client).count) connections")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Family Section
    private func familySection(title: String, icon: String, color: Color, clients: [Client]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(clients.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: min(clients.count, 3)), spacing: 12) {
                ForEach(clients, id: \.id) { relatedClient in
                    FamilyMemberCard(client: relatedClient, color: color)
                }
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Family Connections")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("Add relationships to see the family tree")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Computed Properties
    private var hasNoRelationships: Bool {
        familyTree.parents.isEmpty &&
        familyTree.spouse.isEmpty &&
        familyTree.children.isEmpty &&
        familyTree.siblings.isEmpty &&
        familyTree.extendedFamily.isEmpty &&
        familyTree.businessConnections.isEmpty
    }
    
    // MARK: - Actions
    private func loadFamilyTree() {
        familyTree = relationshipManager.getFamilyTree(for: client)
    }
}

// MARK: - Family Member Card
struct FamilyMemberCard: View {
    let client: Client
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.fill")
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            // Name
            Text(client.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Family Tree Preview
struct FamilyTreeView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyTreeView(
            client: Client(), // Mock client
            relationshipManager: RelationshipManager(context: PersistenceController.shared.container.viewContext, firebaseManager: FirebaseManager.shared)
        )
    }
}

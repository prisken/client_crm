import SwiftUI
import CoreData

// MARK: - Add Relationship Sheet
struct AddRelationshipSheet: View {
    let client: Client
    let relationshipManager: RelationshipManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedClient: Client?
    @State private var selectedRelationshipType: RelationshipOptions.RelationshipType = .parent
    @State private var notes = ""
    @State private var searchText = ""
    @State private var allClients: [Client] = []
    
    var filteredClients: [Client] {
        if searchText.isEmpty {
            return allClients.filter { $0.id != client.id }
        } else {
            return allClients.filter { otherClient in
                otherClient.id != client.id &&
                otherClient.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Client Selection
                        clientSelectionSection
                        
                        // Relationship Type Selection
                        relationshipTypeSection
                        
                        // Notes Section
                        notesSection
                        
                        // Preview Section
                        if selectedClient != nil {
                            previewSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Relationship")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addRelationship()
                    }
                    .disabled(selectedClient == nil)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadClients()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Current Client
                VStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    Text(client.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 80)
                
                // Arrow
                Image(systemName: "arrow.left.and.right")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Selected Client or Placeholder
                VStack {
                    Image(systemName: selectedClient != nil ? "person.circle.fill" : "person.circle")
                        .font(.system(size: 32))
                        .foregroundColor(selectedClient != nil ? .green : .secondary)
                    Text(selectedClient?.displayName ?? "Select Client")
                        .font(.caption)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(selectedClient != nil ? .primary : .secondary)
                }
                .frame(width: 80)
            }
            
            if selectedClient != nil {
                Text("\(client.displayName) is \(selectedRelationshipType.rawValue) of \(selectedClient!.displayName)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Client Selection Section
    private var clientSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Client")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clients...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            // Client List
            LazyVStack(spacing: 8) {
                ForEach(filteredClients.prefix(10), id: \.id) { otherClient in
                    ClientPickerRow(
                        client: otherClient,
                        isSelected: selectedClient?.id == otherClient.id,
                        onTap: {
                            selectedClient = otherClient
                        }
                    )
                }
            }
            .frame(maxHeight: 300)
            
            if filteredClients.isEmpty && !searchText.isEmpty {
                Text("No clients found matching '\(searchText)'")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
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
            Text("Notes (Optional)")
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
            Text("Relationship Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                HStack {
                    Text("Primary:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(client.displayName) is \(selectedRelationshipType.rawValue) of \(selectedClient!.displayName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Inverse:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(selectedClient!.displayName) is \(selectedRelationshipType.inverseRelationship.rawValue) of \(client.displayName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    private func loadClients() {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.firstName, ascending: true)]
        
        do {
            allClients = try viewContext.fetch(request)
        } catch {
            logError("Failed to load clients: \(error.localizedDescription)")
        }
    }
    
    private func addRelationship() {
        guard let selectedClient = selectedClient else { return }
        
        relationshipManager.createRelationship(
            between: client,
            and: selectedClient,
            type: selectedRelationshipType,
            notes: notes.isEmpty ? nil : notes
        )
        
        dismiss()
    }
}

// MARK: - Client Picker Row
struct ClientPickerRow: View {
    let client: Client
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "person.circle")
                .font(.title2)
                .foregroundColor(isSelected ? .green : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(client.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                
                if let email = client.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onTap()
        }
    }
}

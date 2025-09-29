import SwiftUI
import CoreData

// MARK: - Bulk Task Creation View
struct BulkTaskCreationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    @State private var taskTitle = ""
    @State private var taskNotes = ""
    @State private var selectedClients: Set<Client> = []
    @State private var allClients: [Client] = []
    @State private var searchText = ""
    @State private var showingConfirmation = false
    @State private var clientFilter = ClientFilter()
    
    var filteredClients: [Client] {
        var filtered = allClients
        
        // Apply search text filter
        if !searchText.isEmpty {
            let lowercaseSearch = searchText.lowercased()
            filtered = filtered.filter { client in
                let firstName = client.firstName?.lowercased() ?? ""
                let lastName = client.lastName?.lowercased() ?? ""
                return firstName.contains(lowercaseSearch) || lastName.contains(lowercaseSearch)
            }
        }
        
        // Apply active status filter
        switch clientFilter.activeStatus {
        case .all:
            break // No additional filtering needed
        case .active:
            filtered = filtered.filter { $0.isActive }
        case .inactive:
            filtered = filtered.filter { !$0.isActive }
        }
        
        // Apply tag filter
        if !clientFilter.selectedTags.isEmpty {
            filtered = filtered.filter { client in
                client.hasAnyOfTags(clientFilter.selectedTags)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Compact Task Details Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task Details")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        TextField("Task Title", text: $taskTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        TextField("Notes (Optional)", text: $taskNotes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(2...4)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // Client Selection Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Select Clients")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(selectedClients.count) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Compact Filter Section
                    CompactClientFilterView(filter: $clientFilter, tagManager: TagManager.shared)
                        .padding(.horizontal)
                    
                    // Search Bar
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    // Select All/None buttons (Compact)
                    HStack {
                        Button("Select All") {
                            selectedClients = Set(filteredClients)
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Button("Select None") {
                            selectedClients.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Empty state
                    if allClients.isEmpty {
                        EmptyStateView(
                            icon: "person.2",
                            title: "No Clients Found",
                            subtitle: "Add clients first to create bulk tasks"
                        )
                    } else if filteredClients.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: searchText.isEmpty ? "No clients found" : "No clients match your search",
                            subtitle: searchText.isEmpty ? "Add clients first to create bulk tasks" : "Try a different search term"
                        )
                    } else {
                        List {
                            ForEach(filteredClients, id: \.self) { client in
                                ClientSelectionRow(
                                    client: client,
                                    isSelected: selectedClients.contains(client)
                                ) {
                                    toggleClientSelection(client)
                                }
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .navigationTitle("Create Bulk Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        showingConfirmation = true
                    }
                    .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedClients.isEmpty)
                }
            }
        }
        .onAppear {
            loadClients()
        }
        .confirmationDialog(
            "Create Task for \(selectedClients.count) Clients",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Create Tasks") {
                createBulkTasks()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will create the task '\(taskTitle)' for \(selectedClients.count) selected clients.")
        }
    }
    
    private func loadClients() {
        var currentUser = authManager.currentUser
        
        // If no current user, try to load the first available user or create a default one
        if currentUser == nil {
            let userRequest: NSFetchRequest<User> = User.fetchRequest()
            userRequest.fetchLimit = 1
            
            do {
                let users = try viewContext.fetch(userRequest)
                if let user = users.first {
                    currentUser = user
                    authManager.currentUser = user
                } else {
                    currentUser = createDefaultUser()
                }
            } catch {
                currentUser = createDefaultUser()
            }
        }
        
        guard let user = currentUser else { return }
        
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.predicate = NSPredicate(format: "owner == %@", user)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Client.lastName, ascending: true),
            NSSortDescriptor(keyPath: \Client.firstName, ascending: true)
        ]
        
        do {
            allClients = try viewContext.fetch(request)
        } catch {
            logError("Error loading clients: \(error)")
        }
    }
    
    private func createDefaultUser() -> User? {
        let user = User(context: viewContext)
        user.id = UUID()
        user.email = "default@agent.com"
        user.role = "agent"
        user.passwordHash = "default"
        user.createdAt = Date()
        user.updatedAt = Date()
        
        do {
            try viewContext.save()
            return user
        } catch {
            logError("Failed to create default user: \(error)")
            return nil
        }
    }
    
    private func toggleClientSelection(_ client: Client) {
        if selectedClients.contains(client) {
            selectedClients.remove(client)
        } else {
            selectedClients.insert(client)
        }
    }
    
    private func createBulkTasks() {
        guard !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let taskTitleTrimmed = taskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let taskNotesTrimmed = taskNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var createdTasks: [ClientTask] = []
        
        for client in selectedClients {
            let task = ClientTask(context: viewContext)
            task.id = UUID()
            task.title = taskTitleTrimmed
            task.notes = taskNotesTrimmed.isEmpty ? nil : taskNotesTrimmed
            task.isCompleted = false
            task.createdAt = Date()
            task.updatedAt = Date()
            task.client = client
            createdTasks.append(task)
        }
        
        do {
            try viewContext.save()
            
            // Sync all tasks to Firebase
            for task in createdTasks {
                firebaseManager.syncTask(task)
            }
            
            dismiss()
        } catch {
            logError("Error creating bulk tasks: \(error)")
        }
    }
}

// MARK: - Client Selection Row
struct ClientSelectionRow: View {
    let client: Client
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(client.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let phone = client.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let email = client.email, !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

// MARK: - Note: Client displayName extension is already defined in ClientDetailView.swift

#Preview {
    BulkTaskCreationView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager())
}

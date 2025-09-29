import SwiftUI
import CoreData

struct ClientsListView: View {
    @ObservedObject var viewModel: ClientsViewModel
    let searchText: String
    @Binding var selectedClient: Client?
    let onDeleteClient: (Client) -> Void
    @State private var showingDeleteConfirmation = false
    @State private var clientToDelete: Client?
    @State private var clientFilter = ClientFilter()
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    init(viewModel: ClientsViewModel, searchText: String, selectedClient: Binding<Client?>, onDeleteClient: @escaping (Client) -> Void) {
        self.viewModel = viewModel
        self.searchText = searchText
        self._selectedClient = selectedClient
        self.onDeleteClient = onDeleteClient
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Section - Compact
            ClientFilterView(filter: $clientFilter, tagManager: TagManager.shared)
                .padding(.horizontal, DeviceInfo.compactHeaderPadding)
                .padding(.top, DeviceInfo.isIPhone ? 4 : 0)
            
            // Clients List
            if viewModel.clients.isEmpty {
                EmptyStateView(
                    icon: "person.2.fill",
                    title: "No Clients Yet",
                    subtitle: "Add your first client to get started"
                )
            } else if filteredClients.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "No clients match your filters",
                    subtitle: "Try adjusting your search or filter criteria"
                )
            } else {
                List(selection: $selectedClient) {
                    ForEach(filteredClients) { client in
                        ClientRowView(client: client) {
                            selectedClient = client
                        }
                        .tag(client)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                onDeleteClient(client)
                            }
                            
                            Button("Edit") {
                                selectedClient = client
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete(perform: deleteClients)
                }
                .listStyle(PlainListStyle())
            }
        }
        .confirmationDialog(
            type: .deleteClient,
            isPresented: $showingDeleteConfirmation,
            onConfirm: confirmDeleteClient,
            customMessage: clientToDelete != nil ? 
                "Are you sure you want to delete '\(clientToDelete?.firstName ?? "") \(clientToDelete?.lastName ?? "")'? This action cannot be undone and will remove all associated data." :
                "Are you sure you want to delete the selected clients? This action cannot be undone and will remove all associated data."
        )
    }
    
    private var filteredClients: [Client] {
        var filtered = viewModel.clients
        
        // Apply search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { client in
                let fullName = "\(client.firstName ?? "") \(client.lastName ?? "")"
                return fullName.localizedCaseInsensitiveContains(searchText) ||
                       client.email?.localizedCaseInsensitiveContains(searchText) == true ||
                       client.phone?.localizedCaseInsensitiveContains(searchText) == true
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
    
    private func deleteClients(offsets: IndexSet) {
        if offsets.count == 1 {
            let client = filteredClients[offsets.first!]
            clientToDelete = client
            showingDeleteConfirmation = true
        } else {
            // For multiple deletions, show a different confirmation
            clientToDelete = nil
            showingDeleteConfirmation = true
        }
    }
    
    private func confirmDeleteClient() {
        guard let client = clientToDelete else { return }
        
        withAnimation {
            // Delete from Firebase first
            firebaseManager.deleteClient(client)
            
            // Then delete from Core Data
            viewContext.delete(client)
            
            do {
                try viewContext.save()
                viewModel.loadClients(context: viewContext)
            } catch {
                logError("Error deleting client: \(error.localizedDescription)")
            }
        }
        
        clientToDelete = nil
    }
}


import SwiftUI
import CoreData

struct ClientsListView: View {
    @ObservedObject var viewModel: ClientsViewModel
    let searchText: String
    @Binding var selectedClient: Client?
    let onDeleteClient: (Client) -> Void
    @State private var showingDeleteConfirmation = false
    @State private var clientToDelete: Client?
    
    var body: some View {
        VStack {
            if viewModel.clients.isEmpty {
                EmptyStateView(
                    icon: "person.2.fill",
                    title: "No Clients Yet",
                    subtitle: "Add your first client to get started"
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
        if searchText.isEmpty {
            return viewModel.clients
        } else {
            return viewModel.clients.filter { client in
                let fullName = "\(client.firstName ?? "") \(client.lastName ?? "")"
                return fullName.localizedCaseInsensitiveContains(searchText) ||
                       client.email?.localizedCaseInsensitiveContains(searchText) == true ||
                       client.phone?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
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
            viewModel.context.delete(client)
            
            do {
                try viewModel.context.save()
                viewModel.loadClients(context: viewModel.context)
            } catch {
                logError("Error deleting client: \(error.localizedDescription)")
            }
        }
        
        clientToDelete = nil
    }
}


import SwiftUI
import CoreData

struct ClientsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var viewModel = ClientsViewModel()
    
    // MARK: - State
    @State private var showingAddClient = false
    @State private var showingBulkAddClient = false
    @State private var searchText = ""
    @State private var selectedClient: Client?
    @State private var clientToDelete: Client?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with search and add button
            ClientsHeaderView(
                searchText: $searchText,
                onAddSingle: { showingAddClient = true },
                onAddBulk: { showingBulkAddClient = true }
            )
            
            // Main content area
            ClientsContentView(
                viewModel: viewModel,
                searchText: searchText,
                selectedClient: $selectedClient,
                onDeleteClient: { client in
                    clientToDelete = client
                    showingDeleteConfirmation = true
                }
            )
        }
        .navigationTitle("Clients")
        .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Fetch from Firebase first, then load local clients
                firebaseManager.fetchAllData(context: viewContext)
                // Load local data after Firebase sync
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    viewModel.loadClients(context: viewContext, currentUser: authManager.currentUser)
                }
            }
        .sheet(isPresented: $showingAddClient) {
            AddClientView()
                .environment(\.managedObjectContext, viewContext)
        }
        .onChange(of: showingAddClient) { _, isShowing in
            if !isShowing {
                viewModel.loadClients(context: viewContext, currentUser: authManager.currentUser)
            }
        }
        .sheet(isPresented: $showingBulkAddClient) {
            BulkAddClientsView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(authManager)
        }
        .onChange(of: showingBulkAddClient) { _, isShowing in
            if !isShowing {
                viewModel.loadClients(context: viewContext, currentUser: authManager.currentUser)
            }
        }
        .alert("Delete Client", isPresented: $showingDeleteConfirmation, presenting: clientToDelete) { client in
            Button("Delete", role: .destructive) {
                deleteClient(client)
            }
            Button("Cancel", role: .cancel) {
                clientToDelete = nil
            }
        } message: { client in
            Text("Are you sure you want to delete \(client.firstName ?? "") \(client.lastName ?? "")? This action cannot be undone.")
        }
    }
    
    // MARK: - Private Methods
    private func deleteClient(_ client: Client) {
        withAnimation {
            // Delete from Firebase first
            firebaseManager.deleteClient(client)
            
            // Then delete from Core Data
            viewContext.delete(client)
            
            do {
                try viewContext.save()
                viewModel.loadClients(context: viewContext)
                if selectedClient?.id == client.id {
                    selectedClient = nil
                }
            } catch {
                print("Error deleting client: \(error)")
            }
        }
    }
}

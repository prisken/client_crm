import SwiftUI
import CoreData

struct ClientsContentView: View {
    @ObservedObject var viewModel: ClientsViewModel
    let searchText: String
    @Binding var selectedClient: Client?
    let onDeleteClient: (Client) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Side - Clients List
            ClientsListView(
                viewModel: viewModel,
                searchText: searchText,
                selectedClient: $selectedClient,
                onDeleteClient: onDeleteClient
            )
            .frame(minWidth: 400, maxWidth: 500)
            .background(Color(.systemGray6))
            
            Divider()
            
            // Right Side - Client Details
            if let client = selectedClient {
                ClientDetailView(client: client)
                    .environment(\.managedObjectContext, viewModel.context)
            } else {
                EmptyClientDetailView()
            }
        }
    }
}

struct EmptyClientDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Select a Client")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a client from the list to view their details and manage follow-ups")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}


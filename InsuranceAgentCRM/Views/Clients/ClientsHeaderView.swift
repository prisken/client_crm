import SwiftUI

struct ClientsHeaderView: View {
    @Binding var searchText: String
    let onAddSingle: () -> Void
    let onAddBulk: () -> Void
    
    var body: some View {
        HStack {
            SearchBar(text: $searchText)
                .frame(maxWidth: .infinity)
            
            Menu {
                Button(action: onAddSingle) {
                    Label("Add Single Client", systemImage: "person.badge.plus")
                }
                
                Button(action: onAddBulk) {
                    Label("Bulk Add Clients", systemImage: "person.2.badge.plus")
                }
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
}


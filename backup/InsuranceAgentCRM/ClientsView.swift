import SwiftUI
import CoreData

struct ClientsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = ClientsViewModel()
    @State private var showingAddClient = false
    @State private var searchText = ""
    @State private var selectedClient: Client?
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Clients List
                if viewModel.clients.isEmpty {
                    EmptyStateView(
                        icon: "person.2.fill",
                        title: "No Clients Yet",
                        subtitle: "Add your first client to get started"
                    )
                } else {
                    List {
                        ForEach(filteredClients) { client in
                            ClientRowView(client: client) {
                                selectedClient = client
                            }
                        }
                        .onDelete(perform: deleteClients)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddClient = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddClient) {
                AddClientView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $selectedClient) { client in
                ClientDetailView(client: client)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onAppear {
            viewModel.loadClients(context: viewContext)
        }
    }
    
    private var filteredClients: [Client] {
        if searchText.isEmpty {
            return viewModel.clients
        } else {
            return viewModel.clients.filter { client in
                let fullName = "\(client.firstName ?? "") \(client.lastName ?? "")"
                return fullName.localizedCaseInsensitiveContains(searchText) ||
                       client.email?.localizedCaseInsensitiveContains(searchText) == true ||
                       client.phone.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func deleteClients(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let client = filteredClients[index]
                viewContext.delete(client)
            }
            
            do {
                try viewContext.save()
                viewModel.loadClients(context: viewContext)
            } catch {
                print("Error deleting client: \(error)")
            }
        }
    }
}

struct ClientRowView: View {
    let client: Client
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Avatar
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(initials)
                            .font(.headline)
                            .foregroundColor(.blue)
                    )
                
                // Client Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let email = client.email {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(client.phone)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicators
                VStack(alignment: .trailing, spacing: 4) {
                    if client.whatsappOptIn {
                        Image(systemName: "message.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    
                    if let tags = client.tags, !tags.isEmpty {
                        Text(tags.first ?? "")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var initials: String {
        let first = client.firstName?.prefix(1) ?? ""
        let last = client.lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
}

struct AddClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var dob = Date()
    @State private var address = ""
    @State private var notes = ""
    @State private var whatsappOptIn = false
    @State private var tags: [String] = []
    @State private var newTag = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                }
                
                Section("Address") {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Communication") {
                    Toggle("WhatsApp Opt-in", isOn: $whatsappOptIn)
                }
                
                Section("Tags") {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button("Remove") {
                                tags.removeAll { $0 == tag }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add tag", text: $newTag)
                        Button("Add") {
                            if !newTag.isEmpty {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                    }
                }
            }
            .navigationTitle("Add Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveClient()
                    }
                    .disabled(firstName.isEmpty || lastName.isEmpty || phone.isEmpty)
                }
            }
        }
    }
    
    private func saveClient() {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.firstName = firstName
        client.lastName = lastName
        client.email = email.isEmpty ? nil : email
        client.phone = phone
        client.dob = dob
        client.address = address.isEmpty ? nil : address
        client.notes = notes.isEmpty ? nil : notes
        client.whatsappOptIn = whatsappOptIn
        client.whatsappOptInDate = whatsappOptIn ? Date() : nil
        client.tags = tags.isEmpty ? nil : tags
        client.createdAt = Date()
        client.updatedAt = Date()
        client.owner = authManager.currentUser
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving client: \(error)")
        }
    }
}

struct ClientDetailView: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditClient = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Text(initials)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            if let email = client.email {
                                Text(email)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(client.phone)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Quick Actions
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ActionButton(
                            title: "Call",
                            icon: "phone.fill",
                            color: .green
                        ) {
                            // Implement call functionality
                        }
                        
                        ActionButton(
                            title: "WhatsApp",
                            icon: "message.fill",
                            color: .green
                        ) {
                            // Implement WhatsApp functionality
                        }
                        
                        ActionButton(
                            title: "Email",
                            icon: "envelope.fill",
                            color: .blue
                        ) {
                            // Implement email functionality
                        }
                        
                        ActionButton(
                            title: "Add Task",
                            icon: "plus.circle.fill",
                            color: .orange
                        ) {
                            // Implement add task functionality
                        }
                    }
                    
                    // Client Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Information")
                            .font(.headline)
                        
                        InfoRow(label: "Date of Birth", value: client.dob.formatted(date: .abbreviated, time: .omitted))
                        
                        if let address = client.address {
                            InfoRow(label: "Address", value: address)
                        }
                        
                        if let notes = client.notes {
                            InfoRow(label: "Notes", value: notes)
                        }
                        
                        InfoRow(label: "WhatsApp Opt-in", value: client.whatsappOptIn ? "Yes" : "No")
                        
                        if let tags = client.tags, !tags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Tags")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 80))
                                ], spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Client Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditClient = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditClient) {
            EditClientView(client: client)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var initials: String {
        let first = client.firstName?.prefix(1) ?? ""
        let last = client.lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct EditClientView: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var firstName: String
    @State private var lastName: String
    @State private var email: String
    @State private var phone: String
    @State private var dob: Date
    @State private var address: String
    @State private var notes: String
    @State private var whatsappOptIn: Bool
    @State private var tags: [String]
    @State private var newTag = ""
    
    init(client: Client) {
        self.client = client
        _firstName = State(initialValue: client.firstName ?? "")
        _lastName = State(initialValue: client.lastName ?? "")
        _email = State(initialValue: client.email ?? "")
        _phone = State(initialValue: client.phone)
        _dob = State(initialValue: client.dob)
        _address = State(initialValue: client.address ?? "")
        _notes = State(initialValue: client.notes ?? "")
        _whatsappOptIn = State(initialValue: client.whatsappOptIn)
        _tags = State(initialValue: client.tags ?? [])
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                }
                
                Section("Address") {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Communication") {
                    Toggle("WhatsApp Opt-in", isOn: $whatsappOptIn)
                }
                
                Section("Tags") {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button("Remove") {
                                tags.removeAll { $0 == tag }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add tag", text: $newTag)
                        Button("Add") {
                            if !newTag.isEmpty {
                                tags.append(newTag)
                                newTag = ""
                            }
                        }
                        .disabled(newTag.isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Client")
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
                    .disabled(firstName.isEmpty || lastName.isEmpty || phone.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        client.firstName = firstName
        client.lastName = lastName
        client.email = email.isEmpty ? nil : email
        client.phone = phone
        client.dob = dob
        client.address = address.isEmpty ? nil : address
        client.notes = notes.isEmpty ? nil : notes
        client.whatsappOptIn = whatsappOptIn
        client.whatsappOptInDate = whatsappOptIn ? (client.whatsappOptInDate ?? Date()) : nil
        client.tags = tags.isEmpty ? nil : tags
        client.updatedAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving client: \(error)")
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search clients...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

class ClientsViewModel: ObservableObject {
    @Published var clients: [Client] = []
    
    func loadClients(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Client.lastName, ascending: true),
            NSSortDescriptor(keyPath: \Client.firstName, ascending: true)
        ]
        
        do {
            clients = try context.fetch(request)
        } catch {
            print("Error loading clients: \(error)")
        }
    }
}

#Preview {
    ClientsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager())
}

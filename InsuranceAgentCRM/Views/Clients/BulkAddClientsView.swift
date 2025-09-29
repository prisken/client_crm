import SwiftUI
import CoreData

struct BulkAddClientsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var viewModel = ClientsViewModel()
    
    // MARK: - State
    @State private var clientEntries: [BulkClientEntry] = []
    @State private var isProcessing = false
    @State private var processedCount = 0
    @State private var errorCount = 0
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                BulkAddHeaderView()
                
                // Client entries list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Array(clientEntries.enumerated()), id: \.offset) { index, entry in
                            ClientEntryRow(
                                entry: $clientEntries[index],
                                onRemove: {
                                    clientEntries.remove(at: index)
                                }
                            )
                        }
                        
                        AddAnotherClientButton {
                            addNewClient()
                        }
                    }
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Processing indicator
                if isProcessing {
                    ProcessingIndicatorView(
                        processedCount: processedCount,
                        totalCount: clientEntries.count
                    )
                }
                
                // Success message
                if showSuccess {
                    SuccessMessageView(
                        processedCount: processedCount,
                        errorCount: errorCount
                    )
                }
                
                Spacer()
                
                // Action buttons
                BulkAddActionButtons(
                    clientEntries: clientEntries,
                    isProcessing: isProcessing,
                    onCancel: { dismiss() },
                    onAddAll: { processClients() }
                )
            }
            .navigationTitle("Bulk Add Clients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .disabled(isProcessing)
                }
            }
        }
        .onAppear {
            if clientEntries.isEmpty {
                addNewClient()
            }
        }
    }
    
    // MARK: - Private Methods
    private func addNewClient() {
        clientEntries.append(BulkClientEntry(
            firstName: "",
            lastName: "",
            phone: "",
            sex: "Select",
            age: 0
        ))
    }
    
    private func processClients() {
        isProcessing = true
        processedCount = 0
        errorCount = 0
        
        let validEntries = clientEntries.filter { entry in
            !entry.firstName.isEmpty && !entry.lastName.isEmpty && !entry.phone.isEmpty
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            for entry in validEntries {
                DispatchQueue.main.async {
                    self.createClient(from: entry)
                }
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            DispatchQueue.main.async {
                self.isProcessing = false
                self.viewModel.loadClients(context: self.viewContext)
                if self.processedCount > 0 {
                    self.showSuccess = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.dismiss()
                    }
                }
            }
        }
    }
    
    private func createClient(from entry: BulkClientEntry) {
        let client = Client(context: viewContext)
        client.id = UUID()
        client.firstName = entry.firstName
        client.lastName = entry.lastName
        client.phone = entry.phone
        client.dob = Date()
        client.sex = entry.sex.isEmpty ? nil : entry.sex
        client.age = entry.age
        client.whatsappOptIn = false
        client.createdAt = Date()
        client.updatedAt = Date()
        // Ensure we have a user for the client
        if let currentUser = authManager.currentUser {
            client.owner = currentUser
        } else {
            // Create a default user if none exists
            let defaultUser = User(context: viewContext)
            defaultUser.id = UUID()
            defaultUser.email = "default@agent.com"
            defaultUser.role = "agent"
            defaultUser.passwordHash = "default"
            defaultUser.createdAt = Date()
            defaultUser.updatedAt = Date()
            client.owner = defaultUser
        }
        
        do {
            try viewContext.save()
            
            // Sync to Firebase
            firebaseManager.syncClient(client)
            
            processedCount += 1
        } catch {
            print("Error saving client \(entry.firstName) \(entry.lastName): \(error)")
            errorCount += 1
        }
    }
}

// MARK: - Supporting Views
struct BulkAddHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bulk Add Clients")
                .font(.title2)
                .fontWeight(.bold)
            Text("Add multiple clients quickly. You can add detailed information later.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

struct ClientEntryRow: View {
    @Binding var entry: BulkClientEntry
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Client \(entry.firstName.isEmpty && entry.lastName.isEmpty ? "New" : "\(entry.firstName) \(entry.lastName)")")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("First Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("First Name", text: $entry.firstName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Last Name", text: $entry.lastName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Phone Number")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Phone Number", text: $entry.phone)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
                    .autocorrectionDisabled()
            }
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sex")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Sex", selection: $entry.sex) {
                        Text("Select").tag("Select")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Age")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Age", value: $entry.age, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .onChange(of: entry.age) { _, newValue in
                            if newValue < 0 {
                                entry.age = 0
                            } else if newValue > 120 {
                                entry.age = 120
                            }
                        }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 16)
    }
}

struct AddAnotherClientButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                Text("Add Another Client")
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.horizontal, 16)
    }
}

struct ProcessingIndicatorView: View {
    let processedCount: Int
    let totalCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Processing \(processedCount) of \(totalCount) clients...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }
}

struct SuccessMessageView: View {
    let processedCount: Int
    let errorCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Successfully added \(processedCount) clients")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            if errorCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("\(errorCount) clients had errors")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }
}

struct BulkAddActionButtons: View {
    let clientEntries: [BulkClientEntry]
    let isProcessing: Bool
    let onCancel: () -> Void
    let onAddAll: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button("Cancel", action: onCancel)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(8)
            
            Button("Add All Clients", action: onAddAll)
                .frame(maxWidth: .infinity)
                .padding()
                .background(clientEntries.isEmpty ? Color(.systemGray4) : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(clientEntries.isEmpty || isProcessing)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Data Models
struct BulkClientEntry {
    var firstName: String
    var lastName: String
    var phone: String
    var sex: String
    var age: Int16
}

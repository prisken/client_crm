import SwiftUI
import CoreData

struct AddClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = ClientsViewModel()
    
    // MARK: - Form Fields
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
    @State private var sex = "Select"
    @State private var age: Int16 = 0
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    HStack {
                        TextField("First Name", text: $firstName)
                        TextField("Last Name", text: $lastName)
                    }
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                    
                    DatePicker("Date of Birth", selection: $dob, displayedComponents: .date)
                    
                    HStack {
                        Picker("Sex", selection: $sex) {
                            Text("Select").tag("Select")
                            Text("Male").tag("Male")
                            Text("Female").tag("Female")
                            Text("Other").tag("Other")
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        TextField("Age", value: $age, format: .number)
                            .keyboardType(.numberPad)
                            .onChange(of: age) { _, newValue in
                                if newValue < 0 {
                                    age = 0
                                } else if newValue > 120 {
                                    age = 120
                                }
                            }
                    }
                }
                
                Section("Additional Information") {
                    TextField("Address", text: $address, axis: .vertical)
                        .lineLimit(3...6)
                    
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
    
    // MARK: - Private Methods
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
        client.tags = tags.isEmpty ? nil : tags as NSObject
        client.sex = sex.isEmpty ? nil : sex
        client.age = age
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
            print("🔍 Client saved successfully: \(client.firstName ?? "") \(client.lastName ?? "")")
            print("🔍 Core Data Context: \(viewContext)")
            print("🔍 Context Persistent Store: \(viewContext.persistentStoreCoordinator?.persistentStores.first?.url?.absoluteString ?? "Unknown")")
            
            // Test if the client was actually saved
            let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
            let savedClients = try viewContext.fetch(fetchRequest)
            print("🔍 Total clients in store after save: \(savedClients.count)")
            
            // Show debug info in UI
            let debugMessage = "Saved: \(client.firstName ?? "") \(client.lastName ?? "")\nTotal clients: \(savedClients.count)\nStore: \(viewContext.persistentStoreCoordinator?.persistentStores.first?.url?.lastPathComponent ?? "Unknown")"
            
            // Show alert with debug info
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Debug Info", message: debugMessage, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(alert, animated: true)
                }
            }
            
            viewModel.loadClients(context: viewContext)
            DispatchQueue.main.async {
                dismiss()
            }
        } catch {
            print("❌ Error saving client: \(error)")
        }
    }
}

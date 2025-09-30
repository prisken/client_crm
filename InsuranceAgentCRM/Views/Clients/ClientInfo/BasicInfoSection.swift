import SwiftUI
import CoreData

// MARK: - Basic Info Section
struct BasicInfoSection: View {
    let client: Client
    @Binding var isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var sex: String = "Select"
    @State private var age: Int16 = 0
    @State private var refreshTrigger = false
    @State private var showingEditor = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Client Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if isEditMode {
                // Both iPad and Mobile: Show edit button that opens sheet
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Name:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                        Button("Edit") {
                            showingEditor = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    
                    HStack {
                        Text("Phone:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.phone ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    if let email = client.email {
                        HStack {
                            Text("Email:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(email)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Text("Sex:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.sex ?? "Not specified")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Age:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.age > 0 ? "\(client.age)" : "Not specified")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Last Updated:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Created:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Name:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Phone:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.phone ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    if let email = client.email {
                        HStack {
                            Text("Email:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(email)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    
                    HStack {
                        Text("Sex:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.sex ?? "Not specified")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Age:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.age > 0 ? "\(client.age)" : "Not specified")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Last Updated:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Created:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(client.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .id(refreshTrigger)
        .onAppear {
            loadClientData()
        }
        .onChange(of: client.id) { _, _ in
            loadClientData()
        }
        .onChange(of: isEditMode) { _, editing in
            if !editing {
                saveClientData()
            }
        }
        .sheet(isPresented: $showingEditor) {
            ClientInfoEditorSheet(
                client: client,
                firstName: $firstName,
                lastName: $lastName,
                phone: $phone,
                email: $email,
                sex: $sex,
                age: $age,
                onSave: {
                    saveClientData()
                }
            )
        }
    }
    
    private func loadClientData() {
        firstName = client.firstName ?? ""
        lastName = client.lastName ?? ""
        phone = client.phone ?? ""
        email = client.email ?? ""
        sex = client.sex ?? "Select"
        age = client.age
    }
    
    private func saveClientData() {
        client.firstName = firstName
        client.lastName = lastName
        client.phone = phone
        client.email = email.isEmpty ? nil : email
        client.sex = sex.isEmpty ? nil : sex
        client.age = age
        client.updatedAt = Date()
        
        do {
            try viewContext.save()
            
            // Sync client to Firebase
            firebaseManager.syncClient(client)
            
            // Force UI refresh by updating the state
            DispatchQueue.main.async {
                refreshTrigger.toggle()
            }
        } catch {
            print("Error saving client data: \(error)")
        }
    }
}

// MARK: - Client Info Editor Sheet
struct ClientInfoEditorSheet: View {
    let client: Client
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var phone: String
    @Binding var email: String
    @Binding var sex: String
    @Binding var age: Int16
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Client Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("First Name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Name")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone Number")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Phone Number", text: $phone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sex")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("Sex", selection: $sex) {
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
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            TextField("Age", value: $age, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Client Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            })
        }
        .onAppear {
            // Load current client data when sheet appears
            firstName = client.firstName ?? ""
            lastName = client.lastName ?? ""
            phone = client.phone ?? ""
            email = client.email ?? ""
            sex = client.sex ?? "Select"
            age = client.age
        }
    }
}

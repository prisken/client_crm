import SwiftUI
import CoreData

// MARK: - Basic Info Section
struct BasicInfoSection: View {
    let client: Client
    @Binding var isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Client Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            if isEditMode {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("First Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("First Name", text: $firstName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Name")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Last Name", text: $lastName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Phone Number")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Phone Number", text: $phone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
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
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
    }
    
    private func loadClientData() {
        firstName = client.firstName ?? ""
        lastName = client.lastName ?? ""
        phone = client.phone ?? ""
        email = client.email ?? ""
    }
    
    private func saveClientData() {
        client.firstName = firstName
        client.lastName = lastName
        client.phone = phone
        client.email = email.isEmpty ? nil : email
        client.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving client data: \(error)")
        }
    }
}

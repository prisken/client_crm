import SwiftUI
import CoreData

// MARK: - Age Section
struct AgeSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var age: Int16 = 0
    @State private var refreshTrigger = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Retirement Age")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isEditMode {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Retirement Age")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter retirement age", value: $age, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .keyboardAware(extraPadding: 20)
                        .onChange(of: age) { _, newValue in
                            // Ensure age is within reasonable bounds
                            if newValue < 0 {
                                age = 0
                            } else if newValue > 120 {
                                age = 120
                            }
                        }
                    
                    Text("Retirement age must be between 0 and 120")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack {
                    Text("Retirement Age:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(age > 0 ? "\(age) years old" : "Not specified")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .id(refreshTrigger)
        .onAppear {
            age = client.age
        }
        .onChange(of: client.id) { _, _ in
            age = client.age
        }
        .onChange(of: isEditMode) { _, editing in
            if !editing {
                saveAge()
            }
        }
    }
    
    private func saveAge() {
        client.age = age
        client.updatedAt = Date()
        
        do {
            try viewContext.save()
            
            // Sync to Firebase
            firebaseManager.syncClient(client)
            
            // Force UI refresh by updating the state
            DispatchQueue.main.async {
                refreshTrigger.toggle()
            }
        } catch {
            print("Error saving age: \(error)")
        }
    }
}

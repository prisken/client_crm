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
    @State private var showingAgeEditor = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Retirement Age")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Retirement Age:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(age > 0 ? "\(age) years old" : "Not specified")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                
                if isEditMode {
                    Button("Edit") {
                        showingAgeEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
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
        .sheet(isPresented: $showingAgeEditor) {
            RetirementAgeEditorSheet(
                currentAge: $age,
                onSave: {
                    saveAge()
                }
            )
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

// MARK: - Retirement Age Editor Sheet
struct RetirementAgeEditorSheet: View {
    @Binding var currentAge: Int16
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var editingAge: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Retirement Age")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Retirement Age")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter retirement age", text: $editingAge)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.title2)
                        .fontWeight(.medium)
                        .onChange(of: editingAge) { _, newValue in
                            // Validate and constrain input
                            if let ageValue = Int16(newValue) {
                                if ageValue < 0 {
                                    editingAge = "0"
                                } else if ageValue > 120 {
                                    editingAge = "120"
                                }
                            } else if !newValue.isEmpty && !newValue.allSatisfy({ $0.isNumber }) {
                                // Remove non-numeric characters
                                editingAge = String(newValue.filter { $0.isNumber })
                            }
                        }
                    
                    Text("Retirement age must be between 0 and 120")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Retirement Age")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if let newAge = Int16(editingAge), newAge >= 0 && newAge <= 120 {
                            currentAge = newAge
                            onSave()
                        }
                        dismiss()
                    }
                    .disabled(editingAge.isEmpty || Int16(editingAge) == nil)
                }
            })
        }
        .onAppear {
            editingAge = currentAge > 0 ? String(currentAge) : ""
        }
    }
}

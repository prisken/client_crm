import SwiftUI
import CoreData

// MARK: - Retirement Date Section
struct RetirementDateSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var retirementDate = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Retirement Planning")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isEditMode {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Desired Retirement Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DatePicker("Retirement Date", selection: $retirementDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                }
            } else {
                HStack {
                    Text("Retirement Date:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(client.retirementDate?.formatted(date: .abbreviated, time: .omitted) ?? "Not set")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            retirementDate = client.retirementDate ?? Date()
        }
        .onChange(of: client.id) { _, _ in
            retirementDate = client.retirementDate ?? Date()
        }
        .onChange(of: isEditMode) { _, editing in
            if !editing {
                saveRetirementDate()
            }
        }
    }
    
    private func saveRetirementDate() {
        client.retirementDate = retirementDate
        client.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving retirement date: \(error)")
        }
    }
}

import SwiftUI
import CoreData

struct ClientDetailView: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isEditMode = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Basic Info (Name, Tel, Email) with Edit/View Mode
                BasicInfoSection(client: client, isEditMode: $isEditMode)
                
                // 2. Task Checklist
                TaskChecklistSection(client: client)
                
                // 3. Stage One: Introduction and Connection
                StageOneSection(client: client, isEditMode: isEditMode)
                
                // 4. Stage Two: Fact Finding
                StageTwoSection(client: client, isEditMode: isEditMode)
                
                // 5. Retirement Date
                RetirementDateSection(client: client, isEditMode: isEditMode)
                
                // 6. Stage Three: Product Pairing
                StageThreeSection(client: client, isEditMode: isEditMode)
            }
            .padding()
        }
        .navigationTitle("\(client.firstName ?? "") \(client.lastName ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditMode ? "Done" : "Edit") {
                    isEditMode.toggle()
                }
            }
        }
        .onAppear {
            logInfo("ClientDetailView appeared for client: \(client.firstName ?? "") \(client.lastName ?? "") (ID: \(client.id?.uuidString ?? "nil"))")
        }
    }
}
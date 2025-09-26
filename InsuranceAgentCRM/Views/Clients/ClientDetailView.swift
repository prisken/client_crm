import SwiftUI
import CoreData

// MARK: - Client Detail View
struct ClientDetailView: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isEditMode = false

    var body: some View {
        VStack(spacing: 0) {
            headerView
            contentView
        }
        .onAppear {
            logInfo("ClientDetailView appeared for client: \(client.displayName) (ID: \(client.id?.uuidString ?? "nil"))")
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text(client.displayName)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button(isEditMode ? "Done" : "Edit") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isEditMode.toggle()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Content View
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 1. Basic Info Section
                BasicInfoSection(client: client, isEditMode: $isEditMode)
                
                // 2. Relationships Section
                RelationshipSection(client: client, isEditMode: isEditMode)
                
                // 3. Task Checklist Section
                TaskChecklistSection(client: client)
                
                // 4. Stage One: Introduction and Connection
                StageOneSection(client: client, isEditMode: isEditMode)
                
                // 5. Stage Two: Fact Finding
                StageTwoSection(client: client, isEditMode: isEditMode)
                
                // 6. Retirement Date Section
                RetirementDateSection(client: client, isEditMode: isEditMode)
                
                // 7. Stage Three: Product Pairing
                StageThreeSection(client: client, isEditMode: isEditMode)
            }
            .padding()
        }
    }
}

// MARK: - Client Extension
extension Client {
    var displayName: String {
        let firstName = self.firstName ?? ""
        let lastName = self.lastName ?? ""
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
}
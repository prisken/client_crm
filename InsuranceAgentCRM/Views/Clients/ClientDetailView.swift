import SwiftUI
import CoreData

// MARK: - Client Detail View
struct ClientDetailView: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var tagManager = TagManager(context: PersistenceController.shared.container.viewContext, firebaseManager: FirebaseManager.shared)
    @State private var isEditMode = false

    var body: some View {
        Group {
            if DeviceInfo.isIPhone {
                // iPhone: Mobile-optimized layout
                VStack(spacing: 0) {
                    headerView
                    contentView
                }
            } else {
                // iPad: Enhanced layout with better space utilization
                VStack(spacing: 0) {
                    headerView
                    contentView
                }
            }
        }
        .onAppear {
            // Reset edit mode when switching to a different client
            if isEditMode {
                isEditMode = false
            }
        }
        .onChange(of: client.id) { oldValue, newValue in
            // Reset edit mode when client changes
            if oldValue != newValue && isEditMode {
                isEditMode = false
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text(client.displayName)
                .font(DeviceInfo.isIPhone ? .title3 : .title2)
                .fontWeight(.semibold)
                .lineLimit(DeviceInfo.isIPhone ? 1 : 2)
            
            Spacer()
            
            Button(isEditMode ? "Done" : "Edit") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isEditMode.toggle()
                    if isEditMode {
                        // Force refresh the view context to ensure all data is fresh
                        viewContext.refreshAllObjects()
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .mobileTouchTarget()
        }
        .mobilePadding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Content View
    private var contentView: some View {
        KeyboardAwareScrollView {
            VStack(alignment: .leading, spacing: DeviceInfo.isIPhone ? DeviceInfo.mobileSpacing : 20) {
                // 1. Basic Info Section
                BasicInfoSection(client: client, isEditMode: $isEditMode)
                
                // 2. Relationships Section
                RelationshipSection(client: client, isEditMode: isEditMode)
                
                // 3. Task Checklist Section
                TaskChecklistSection(client: client)
                
                // 4. Stage One: Introduction and Connection
                StageOneSection(client: client, isEditMode: isEditMode, tagManager: tagManager)
                
                // 5. Stage Two: Fact Finding
                StageTwoSection(client: client, isEditMode: isEditMode)
                
                // 6. Age Section
                AgeSection(client: client, isEditMode: isEditMode)
                
                // 7. Stage Three: Product Pairing
                StageThreeSection(client: client, isEditMode: isEditMode)
            }
            .mobilePadding()
        }
        .onReceive(NotificationCenter.default.publisher(for: .tagInputFocused)) { _ in
            // Handle tag input focus - ensure proper keyboard handling
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // This will trigger the keyboard handling for tag inputs specifically
            }
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
    
    // MARK: - Filtering Helpers
    var isActive: Bool {
        guard let products = self.products as? Set<ClientProduct> else { return false }
        return products.contains { $0.status?.lowercased() == "active" }
    }
    
    var allTags: [String] {
        var tags: [String] = []
        
        if let interests = self.interests as? [String] {
            tags.append(contentsOf: interests)
        }
        
        if let socialStatus = self.socialStatus as? [String] {
            tags.append(contentsOf: socialStatus)
        }
        
        if let lifeStage = self.lifeStage as? [String] {
            tags.append(contentsOf: lifeStage)
        }
        
        return tags
    }
    
    func hasAnyOfTags(_ selectedTags: Set<String>) -> Bool {
        guard !selectedTags.isEmpty else { return true }
        let clientTags = Set(allTags)
        return !clientTags.intersection(selectedTags).isEmpty
    }
}
import SwiftUI
import CoreData

// MARK: - Stage One: Introduction and Connection
struct StageOneSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseManager: FirebaseManager
    @ObservedObject var tagManager: TagManager
    @State private var selectedInterests: Set<String> = []
    @State private var selectedSocialStatus: Set<String> = []
    @State private var selectedLifeStage: Set<String> = []
    @State private var refreshTrigger = false
    
    // MARK: - Collapse States
    @State private var isInterestsCollapsed = false
    @State private var isSocialStatusCollapsed = false
    @State private var isLifeStageCollapsed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stage One: Introduction & Connection")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isEditMode {
                editModeView
            } else {
                viewModeView
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .id(refreshTrigger) // Force view refresh when data changes
        .onAppear {
            loadClientData()
        }
        .onChange(of: client.id) { _, _ in
            clearAndReloadData()
        }
        .onChange(of: isEditMode) { _, editing in
            if !editing {
                saveClientData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.Notifications.tagDeleted)) { notification in
            if let data = notification.object as? (tag: String, category: TagCategory) {
                handleTagDeleted(tag: data.tag, category: data.category)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.Notifications.clientDataChanged)) { _ in
            // Save client data immediately when tags are selected/deselected
            saveClientData()
        }
        .onAppear {
            // Refresh tags from Firebase when this section appears
            tagManager.refreshTags()
        }
    }
    
    // MARK: - Edit Mode View
    private var editModeView: some View {
        VStack(spacing: 20) {
            // Interests Section
            CollapsibleTagSection(
                title: "Interests",
                isCollapsed: $isInterestsCollapsed,
                selectedCount: selectedInterests.count,
                totalCount: 0 // Dynamic count will be handled by TagManager
            ) {
                DynamicTagSelectionView(
                    category: .interest,
                    selectedTags: $selectedInterests,
                    tagManager: TagManager.shared
                )
            }
            
            // Social Status Section
            CollapsibleTagSection(
                title: "Social Status",
                isCollapsed: $isSocialStatusCollapsed,
                selectedCount: selectedSocialStatus.count,
                totalCount: 0 // Dynamic count will be handled by TagManager
            ) {
                DynamicTagSelectionView(
                    category: .socialStatus,
                    selectedTags: $selectedSocialStatus,
                    tagManager: TagManager.shared
                )
            }
            
            // Life Stage Section
            CollapsibleTagSection(
                title: "Life Stage",
                isCollapsed: $isLifeStageCollapsed,
                selectedCount: selectedLifeStage.count,
                totalCount: 0 // Dynamic count will be handled by TagManager
            ) {
                DynamicTagSelectionView(
                    category: .lifeStage,
                    selectedTags: $selectedLifeStage,
                    tagManager: TagManager.shared
                )
            }
        }
    }
    
    // MARK: - View Mode View
    private var viewModeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let interests = client.interests as? [String], !interests.isEmpty {
                CollapsibleDisplaySection(
                    title: "Interests",
                    isCollapsed: $isInterestsCollapsed,
                    tagCount: interests.count
                ) {
                    DynamicTagDisplayView(
                        category: .interest,
                        selectedTags: Set(interests),
                        tagManager: TagManager.shared
                    )
                }
            }
            
            if let socialStatus = client.socialStatus as? [String], !socialStatus.isEmpty {
                CollapsibleDisplaySection(
                    title: "Social Status",
                    isCollapsed: $isSocialStatusCollapsed,
                    tagCount: socialStatus.count
                ) {
                    DynamicTagDisplayView(
                        category: .socialStatus,
                        selectedTags: Set(socialStatus),
                        tagManager: TagManager.shared
                    )
                }
            }
            
            if let lifeStage = client.lifeStage as? [String], !lifeStage.isEmpty {
                CollapsibleDisplaySection(
                    title: "Life Stage",
                    isCollapsed: $isLifeStageCollapsed,
                    tagCount: lifeStage.count
                ) {
                    DynamicTagDisplayView(
                        category: .lifeStage,
                        selectedTags: Set(lifeStage),
                        tagManager: TagManager.shared
                    )
                }
            }
            
            if !hasAnyTags {
                Text("No connection information added yet")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var hasAnyTags: Bool {
        let hasInterests = (client.interests as? [String])?.isEmpty == false
        let hasSocialStatus = (client.socialStatus as? [String])?.isEmpty == false
        let hasLifeStage = (client.lifeStage as? [String])?.isEmpty == false
        return hasInterests || hasSocialStatus || hasLifeStage
    }
    
    // MARK: - Data Management
    private func clearAndReloadData() {
        selectedInterests = Set()
        selectedSocialStatus = Set()
        selectedLifeStage = Set()
        loadClientData()
    }
    
    // MARK: - Handle Tag Deletion
    private func handleTagDeleted(tag: String, category: TagCategory) {
        // Remove the deleted tag from the current client's selections
        switch category {
        case .interest:
            selectedInterests.remove(tag)
        case .socialStatus:
            selectedSocialStatus.remove(tag)
        case .lifeStage:
            selectedLifeStage.remove(tag)
        }
        
        // Force UI refresh
        DispatchQueue.main.async {
            self.refreshTrigger.toggle()
        }
        
        logInfo("Tag '\(tag)' deleted from category '\(category.rawValue)' - removed from client selections")
    }
    
    private func loadClientData() {
        if let interests = client.interests as? [String] {
            selectedInterests = Set(interests)
        } else {
            selectedInterests = Set()
        }
        
        if let socialStatus = client.socialStatus as? [String] {
            selectedSocialStatus = Set(socialStatus)
        } else {
            selectedSocialStatus = Set()
        }
        
        if let lifeStage = client.lifeStage as? [String] {
            selectedLifeStage = Set(lifeStage)
        } else {
            selectedLifeStage = Set()
        }
    }
    
    private func saveClientData() {
        // Update the client object with selected tags
        client.interests = Array(selectedInterests) as NSObject
        client.socialStatus = Array(selectedSocialStatus) as NSObject
        client.lifeStage = Array(selectedLifeStage) as NSObject
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
            logError("Failed to save client connection data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Collapsible Tag Section
struct CollapsibleTagSection<Content: View>: View {
    let title: String
    @Binding var isCollapsed: Bool
    let selectedCount: Int
    let totalCount: Int
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with collapse/expand button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isCollapsed.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Selection count badge
                    if selectedCount > 0 {
                        Text("\(selectedCount) selected")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    
                    // Total count
                    Text("\(totalCount) options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content (collapsible)
            if !isCollapsed {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Collapsible Display Section
struct CollapsibleDisplaySection<Content: View>: View {
    let title: String
    @Binding var isCollapsed: Bool
    let tagCount: Int
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with collapse/expand button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isCollapsed.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Tag count badge
                    Text("\(tagCount) tags")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(8)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content (collapsible)
            if !isCollapsed {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

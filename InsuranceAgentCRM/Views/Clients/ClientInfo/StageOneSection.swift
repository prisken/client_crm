import SwiftUI
import CoreData

// MARK: - Stage One: Introduction and Connection
struct StageOneSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedInterests: Set<String> = []
    @State private var selectedSocialStatus: Set<String> = []
    @State private var selectedLifeStage: Set<String> = []
    @State private var refreshTrigger = false
    
    // MARK: - Tag Options
    private let interestOptions = TagOptions.interestOptions
    private let socialStatusOptions = TagOptions.socialStatusOptions
    private let lifeStageOptions = TagOptions.lifeStageOptions
    
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
    }
    
    // MARK: - Edit Mode View
    private var editModeView: some View {
        VStack(spacing: 20) {
            TagSelectionView(
                title: "Interests",
                options: interestOptions,
                selectedTags: $selectedInterests
            )
            
            TagSelectionView(
                title: "Social Status",
                options: socialStatusOptions,
                selectedTags: $selectedSocialStatus
            )
            
            TagSelectionView(
                title: "Life Stage",
                options: lifeStageOptions,
                selectedTags: $selectedLifeStage
            )
        }
    }
    
    // MARK: - View Mode View
    private var viewModeView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let interests = client.interests as? [String], !interests.isEmpty {
                TagDisplayView(title: "Interests", tags: interests)
            }
            
            if let socialStatus = client.socialStatus as? [String], !socialStatus.isEmpty {
                TagDisplayView(title: "Social Status", tags: socialStatus)
            }
            
            if let lifeStage = client.lifeStage as? [String], !lifeStage.isEmpty {
                TagDisplayView(title: "Life Stage", tags: lifeStage)
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
            
            // Force UI refresh by updating the state
            DispatchQueue.main.async {
                refreshTrigger.toggle()
            }
        } catch {
            logError("Failed to save client connection data: \(error.localizedDescription)")
        }
    }
}

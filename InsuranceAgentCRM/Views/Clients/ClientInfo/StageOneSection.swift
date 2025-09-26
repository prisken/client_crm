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
    
    private let interestOptions = [
        "Music", "Movies", "Sports", "Reading", "Travel", "Cooking", "Gaming", "Art",
        "Photography", "Dancing", "Fitness", "Gardening", "Technology", "Fashion",
        "Cars", "Pets", "Volunteering", "Investing", "Real Estate", "Business"
    ]
    
    private let socialStatusOptions = [
        "Blue Collar", "White Collar", "Working Class", "Middle Class", "Upper Middle Class",
        "Professional", "Managerial", "Executive", "Entrepreneur", "Student", "Retired",
        "Self-Employed", "Government Employee", "Healthcare Worker", "Teacher", "Engineer"
    ]
    
    private let lifeStageOptions = [
        "Single", "Dating", "Engaged", "Newly Married", "Married", "Divorced", "Widowed",
        "Parent", "New Parent", "Empty Nester", "Grandparent", "Student", "Recent Graduate",
        "Just Started Working", "Mid-Career", "Senior Professional", "Pre-Retirement",
        "Retired", "Young Adult", "Middle Age", "Senior"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stage One: Introduction & Connection")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isEditMode {
                VStack(spacing: 20) {
                    // Interests
                    TagSelectionView(
                        title: "Interests",
                        options: interestOptions,
                        selectedTags: $selectedInterests
                    )
                    
                    // Social Status
                    TagSelectionView(
                        title: "Social Status",
                        options: socialStatusOptions,
                        selectedTags: $selectedSocialStatus
                    )
                    
                    // Life Stage
                    TagSelectionView(
                        title: "Life Stage",
                        options: lifeStageOptions,
                        selectedTags: $selectedLifeStage
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    if !(client.interests?.isEmpty ?? true) {
                        TagDisplayView(title: "Interests", tags: client.interests ?? [])
                    }
                    
                    if !(client.socialStatus?.isEmpty ?? true) {
                        TagDisplayView(title: "Social Status", tags: client.socialStatus ?? [])
                    }
                    
                    if !(client.lifeStage?.isEmpty ?? true) {
                        TagDisplayView(title: "Life Stage", tags: client.lifeStage ?? [])
                    }
                    
                    if (client.interests?.isEmpty ?? true) && (client.socialStatus?.isEmpty ?? true) && (client.lifeStage?.isEmpty ?? true) {
                        Text("No connection information added yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
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
        .onChange(of: isEditMode) { _, editing in
            if !editing {
                saveClientData()
            }
        }
    }
    
    private func loadClientData() {
        selectedInterests = Set(client.interests ?? [])
        selectedSocialStatus = Set(client.socialStatus ?? [])
        selectedLifeStage = Set(client.lifeStage ?? [])
    }
    
    private func saveClientData() {
        client.interests = Array(selectedInterests)
        client.socialStatus = Array(selectedSocialStatus)
        client.lifeStage = Array(selectedLifeStage)
        client.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            print("Error saving client connection data: \(error)")
        }
    }
}

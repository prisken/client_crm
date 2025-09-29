import SwiftUI
import CoreData

// MARK: - Add Tag Sheet
struct AddTagSheet: View {
    let category: TagCategory
    @Binding var newTagText: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add New \(category.rawValue) Tag")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                TextField("Enter \(category.rawValue.lowercased()) tag", text: $newTagText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        newTagText = ""
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onSave()
                        dismiss()
                    }
                    .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            })
        }
    }
}

// MARK: - Dynamic Tag Selection View
struct DynamicTagSelectionView: View {
    let category: TagCategory
    @Binding var selectedTags: Set<String>
    @ObservedObject var tagManager: TagManager
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var newTagText = ""
    @State private var showingAddTag = false
    
    init(category: TagCategory, selectedTags: Binding<Set<String>>, tagManager: TagManager) {
        self.category = category
        self._selectedTags = selectedTags
        self.tagManager = tagManager
    }
    
    var body: some View {
        return VStack(alignment: .leading, spacing: 12) {
            // Category Header
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text(category.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                
                // Debug button
                Button(action: {
                    tagManager.debugPrintTags()
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
                
                Button(action: {
                    showingAddTag = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(category.color)
                        .font(.title3)
                }
            }
            
            // Add Tag Section
            if showingAddTag {
                addTagSection
            }
            
            // Tags Grid
            if !availableTags.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(availableTags, id: \.self) { tag in
                        TagChip(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            category: category,
                            onToggle: {
                                toggleTag(tag)
                            },
                            onDelete: {
                                tagManager.deleteTag(tag, from: category)
                            }
                        )
                    }
                }
            } else {
                emptyStateView
            }
        }
        .onAppear {
            // Refresh tags from Firebase when view appears
            tagManager.refreshTags()
        }
    }
    
    // MARK: - Add Tag Section
    private var addTagSection: some View {
        VStack(spacing: 8) {
            Button(action: {
                showingAddTag = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(category.color)
                    Text("Add new \(category.rawValue.lowercased()) tag")
                        .foregroundColor(category.color)
                    Spacer()
                }
                .padding()
                .background(category.color.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingAddTag) {
            AddTagSheet(
                category: category,
                newTagText: $newTagText,
                onSave: {
                    addNewTag()
                }
            )
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 8) {
            Image(systemName: category.icon)
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("No \(category.rawValue.lowercased()) tags yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Add First Tag") {
                showingAddTag = true
            }
            .font(.caption)
            .foregroundColor(category.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Computed Properties
    private var availableTags: [String] {
        let tags = tagManager.getTags(for: category)
        print("DynamicTagSelectionView: Available tags for \(category.rawValue): \(tags)")
        return tags
    }
    
    // MARK: - Actions
    private func addNewTag() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { 
            print("Error: Empty tag text")
            return 
        }
        
        // Get current user and pass it to addTag
        guard let currentUser = authManager.currentUser else {
            print("Error: No current user found")
            return
        }
        
        print("Adding tag: '\(trimmedTag)' for category: \(category.rawValue) with user: \(currentUser.email ?? "unknown")")
        
        tagManager.addTag(trimmedTag, to: category, owner: currentUser)
        newTagText = ""
        showingAddTag = false
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
        
        // Save the selection immediately to Core Data and sync to Firebase
        saveClientData()
    }
    
    private func saveClientData() {
        // This will be implemented by the parent view
        // For now, we'll use a notification to trigger the save
        NotificationCenter.default.post(name: AppConstants.Notifications.clientDataChanged, object: nil)
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let tag: String
    let isSelected: Bool
    let category: TagCategory
    let onToggle: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggle) {
                HStack(spacing: 4) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    
                    Text(tag)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? category.color : Color(.systemGray5))
                .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                showingDeleteConfirmation = true
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .confirmationDialog("Delete Tag", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove '\(tag)' from all clients. This action cannot be undone.")
        }
    }
}

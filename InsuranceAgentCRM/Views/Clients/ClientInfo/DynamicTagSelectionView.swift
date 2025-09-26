import SwiftUI
import CoreData

// MARK: - Dynamic Tag Selection View
struct DynamicTagSelectionView: View {
    let category: TagCategory
    @Binding var selectedTags: Set<String>
    @ObservedObject var tagManager: TagManager
    @State private var newTagText = ""
    @State private var showingAddTag = false
    
    init(category: TagCategory, selectedTags: Binding<Set<String>>, tagManager: TagManager) {
        self.category = category
        self._selectedTags = selectedTags
        self.tagManager = tagManager
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
    }
    
    // MARK: - Add Tag Section
    private var addTagSection: some View {
        VStack(spacing: 8) {
            HStack {
                TextField("Add new \(category.rawValue.lowercased()) tag", text: $newTagText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addNewTag()
                    }
                
                Button("Add") {
                    addNewTag()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            Button("Cancel") {
                showingAddTag = false
                newTagText = ""
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(category.color.opacity(0.1))
        .cornerRadius(8)
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
        tagManager.getTags(for: category)
    }
    
    // MARK: - Actions
    private func addNewTag() {
        let trimmedTag = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTag.isEmpty else { return }
        
        print("DEBUG: DynamicTagSelectionView adding tag '\(trimmedTag)' to category '\(category.rawValue)'")
        tagManager.addTag(trimmedTag, to: category)
        newTagText = ""
        showingAddTag = false
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
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

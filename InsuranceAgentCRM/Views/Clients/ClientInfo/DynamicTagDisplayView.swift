import SwiftUI
import CoreData

// MARK: - Dynamic Tag Display View
struct DynamicTagDisplayView: View {
    let category: TagCategory
    let selectedTags: Set<String>
    @ObservedObject var tagManager: TagManager
    
    init(category: TagCategory, selectedTags: Set<String>, tagManager: TagManager) {
        self.category = category
        self.selectedTags = selectedTags
        self.tagManager = tagManager
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Category Header
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(selectedTags.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tags Display
            if selectedTags.isEmpty {
                Text("No \(category.rawValue.lowercased()) tags selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 2), spacing: 6) {
                    ForEach(Array(selectedTags), id: \.self) { tag in
                        DynamicTagDisplayChip(tag: tag, category: category)
                    }
                }
            }
        }
    }
}

// MARK: - Dynamic Tag Display Chip
struct DynamicTagDisplayChip: View {
    let tag: String
    let category: TagCategory
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption)
                .foregroundColor(category.color)
            
            Text(tag)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.1))
        .cornerRadius(12)
    }
}

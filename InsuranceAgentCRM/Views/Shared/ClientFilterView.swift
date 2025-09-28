import SwiftUI
import CoreData

// MARK: - Client Filter Model
struct ClientFilter: Equatable {
    var selectedTags: Set<String> = []
    var activeStatus: ActiveStatusFilter = .all
    var searchText: String = ""
    
    enum ActiveStatusFilter: String, CaseIterable {
        case all = "All Clients"
        case active = "Active Only"
        case inactive = "Inactive Only"
        
        var icon: String {
            switch self {
            case .all: return "person.2.fill"
            case .active: return "checkmark.circle.fill"
            case .inactive: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .active: return .green
            case .inactive: return .red
            }
        }
    }
}

// MARK: - Client Filter View
struct ClientFilterView: View {
    @Binding var filter: ClientFilter
    @ObservedObject var tagManager: TagManager
    @State private var isExpanded = false
    @State private var showingTagSelection = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Filter Header
            HStack {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .foregroundColor(.blue)
                
                Text("Filters")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Active filter count badge
                if hasActiveFilters {
                    Text("\(activeFilterCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .padding(.horizontal)
            
            // Filter Content
            if isExpanded {
                VStack(spacing: 16) {
                    // Active Status Filter
                    activeStatusFilter
                    
                    // Tag Filter
                    tagFilter
                    
                    // Clear Filters Button
                    if hasActiveFilters {
                        Button("Clear All Filters") {
                            clearAllFilters()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingTagSelection) {
            TagSelectionSheet(
                selectedTags: $filter.selectedTags,
                tagManager: tagManager
            )
        }
    }
    
    // MARK: - Active Status Filter
    private var activeStatusFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Client Status")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal)
            
            HStack(spacing: 12) {
                ForEach(ClientFilter.ActiveStatusFilter.allCases, id: \.self) { status in
                    Button(action: {
                        filter.activeStatus = status
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: status.icon)
                                .font(.caption)
                            
                            Text(status.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(filter.activeStatus == status ? status.color : Color(.systemGray5))
                        .foregroundColor(filter.activeStatus == status ? .white : .primary)
                        .cornerRadius(16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Tag Filter
    private var tagFilter: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Select Tags") {
                    showingTagSelection = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            if filter.selectedTags.isEmpty {
                Text("No tags selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(filter.selectedTags), id: \.self) { tag in
                            TagFilterChip(tag: tag) {
                                filter.selectedTags.remove(tag)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var hasActiveFilters: Bool {
        !filter.selectedTags.isEmpty || filter.activeStatus != .all
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if !filter.selectedTags.isEmpty {
            count += 1
        }
        if filter.activeStatus != .all {
            count += 1
        }
        return count
    }
    
    // MARK: - Actions
    private func clearAllFilters() {
        withAnimation(.easeInOut(duration: 0.3)) {
            filter.selectedTags.removeAll()
            filter.activeStatus = .all
        }
    }
}

// MARK: - Tag Filter Chip
struct TagFilterChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(12)
    }
}

// MARK: - Tag Selection Sheet
struct TagSelectionSheet: View {
    @Binding var selectedTags: Set<String>
    @ObservedObject var tagManager: TagManager
    @Environment(\.dismiss) private var dismiss
    @State private var localSelectedTags: Set<String>
    
    init(selectedTags: Binding<Set<String>>, tagManager: TagManager) {
        self._selectedTags = selectedTags
        self.tagManager = tagManager
        self._localSelectedTags = State(initialValue: selectedTags.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tag Categories
                ForEach(TagCategory.allCases, id: \.self) { category in
                    TagCategorySection(
                        category: category,
                        tags: tagManager.getTags(for: category),
                        selectedTags: $localSelectedTags
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedTags = localSelectedTags
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Tag Category Section
struct TagCategorySection: View {
    let category: TagCategory
    let tags: [String]
    @Binding var selectedTags: Set<String>
    
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
                
                Text("\(tags.count) tags")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if tags.isEmpty {
                Text("No \(category.rawValue.lowercased()) tags available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        FilterTagChip(
                            tag: tag,
                            isSelected: selectedTags.contains(tag),
                            category: category
                        ) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Tag Chip
struct FilterTagChip: View {
    let tag: String
    let isSelected: Bool
    let category: TagCategory
    let onToggle: () -> Void
    
    var body: some View {
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
    }
}

// MARK: - Compact Client Filter View (for Bulk Task Creation)
struct CompactClientFilterView: View {
    @Binding var filter: ClientFilter
    @ObservedObject var tagManager: TagManager
    @State private var showingTagSelection = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Filter Header with Active Status
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.blue)
                        .font(.caption)
                    
                    Text("Filters")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Active Status Filter (Inline)
                HStack(spacing: 6) {
                    ForEach(ClientFilter.ActiveStatusFilter.allCases, id: \.self) { status in
                        Button(action: {
                            filter.activeStatus = status
                        }) {
                            Text(status.rawValue)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(filter.activeStatus == status ? status.color : Color(.systemGray5))
                                .foregroundColor(filter.activeStatus == status ? .white : .primary)
                                .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Tag Filter (Compact)
            if !filter.selectedTags.isEmpty {
                HStack {
                    Text("Tags:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(Array(filter.selectedTags), id: \.self) { tag in
                                CompactTagChip(tag: tag) {
                                    filter.selectedTags.remove(tag)
                                }
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                    
                    Spacer()
                }
            }
            
            // Add Tags Button
            HStack {
                Button(action: {
                    showingTagSelection = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption2)
                        Text("Add Tags")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Clear Filters Button
                if hasActiveFilters {
                    Button("Clear") {
                        clearAllFilters()
                    }
                    .font(.caption2)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .sheet(isPresented: $showingTagSelection) {
            TagSelectionSheet(
                selectedTags: $filter.selectedTags,
                tagManager: tagManager
            )
        }
    }
    
    // MARK: - Computed Properties
    private var hasActiveFilters: Bool {
        !filter.selectedTags.isEmpty || filter.activeStatus != .all
    }
    
    // MARK: - Actions
    private func clearAllFilters() {
        withAnimation(.easeInOut(duration: 0.2)) {
            filter.selectedTags.removeAll()
            filter.activeStatus = .all
        }
    }
}

// MARK: - Compact Tag Chip
struct CompactTagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 2) {
            Text(tag)
                .font(.caption2)
                .fontWeight(.medium)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.2))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
}

#Preview {
    ClientFilterView(
        filter: .constant(ClientFilter()),
        tagManager: TagManager(context: PersistenceController.preview.container.viewContext)
    )
}

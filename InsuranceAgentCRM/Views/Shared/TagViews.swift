import SwiftUI

// MARK: - Tag Selection View
struct TagSelectionView: View {
    let title: String
    let options: [String]
    @Binding var selectedTags: Set<String>
    @State private var searchText = ""
    
    // MARK: - Constants
    private let gridColumns = 3
    private let searchThreshold = 20
    private let animationDuration: Double = 0.2
    
    // MARK: - Computed Properties
    private var filteredOptions: [String] {
        if searchText.isEmpty {
            return options
        } else {
            return options.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var shouldShowSearch: Bool {
        options.count > searchThreshold
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            searchView
            tagGridView
            emptyStateView
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(selectedTags.count) selected")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Search View
    @ViewBuilder
    private var searchView: some View {
        if shouldShowSearch {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search \(title.lowercased())...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Tag Grid View
    private var tagGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: gridColumns), spacing: 8) {
            ForEach(filteredOptions, id: \.self) { option in
                TagButton(
                    text: option,
                    isSelected: selectedTags.contains(option),
                    action: { toggleSelection(for: option) }
                )
            }
        }
    }
    
    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        if !searchText.isEmpty && filteredOptions.isEmpty {
            Text("No \(title.lowercased()) found matching '\(searchText)'")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.vertical, 8)
        }
    }
    
    // MARK: - Actions
    private func toggleSelection(for option: String) {
        withAnimation(.easeInOut(duration: animationDuration)) {
            if selectedTags.contains(option) {
                selectedTags.remove(option)
            } else {
                selectedTags.insert(option)
            }
        }
    }
}

// MARK: - Tag Button Component
struct TagButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(backgroundView)
                .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ? Color.blue : Color(.systemGray5))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: 1)
            )
    }
}

// MARK: - Tag Display View
struct TagDisplayView: View {
    let title: String
    let tags: [String]
    
    // MARK: - Constants
    private let gridColumns = 3
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            contentView
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            Text("\(tags.count) tags")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        if tags.isEmpty {
            emptyStateView
        } else {
            tagGridView
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        Text("No \(title.lowercased()) added yet")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .italic()
    }
    
    // MARK: - Tag Grid View
    private var tagGridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: gridColumns), spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                TagDisplayChip(text: tag)
            }
        }
    }
}

// MARK: - Tag Display Chip Component
struct TagDisplayChip: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue)
            )
    }
}

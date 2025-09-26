import SwiftUI

// MARK: - Tag Selection View
struct TagSelectionView: View {
    let title: String
    let options: [String]
    @Binding var selectedTags: Set<String>
    @State private var searchText = ""
    
    private var filteredOptions: [String] {
        if searchText.isEmpty {
            return options
        } else {
            return options.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(selectedTags.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Search bar for large lists
            if options.count > 20 {
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
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(filteredOptions, id: \.self) { option in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedTags.contains(option) {
                                selectedTags.remove(option)
                            } else {
                                selectedTags.insert(option)
                            }
                        }
                    }) {
                        Text(option)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selectedTags.contains(option) ? .white : .primary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedTags.contains(option) ? 
                                          Color.blue : 
                                          Color(.systemGray5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedTags.contains(option) ? 
                                                   Color.blue : 
                                                   Color(.systemGray4), lineWidth: 1)
                                    )
                            )
                            .scaleEffect(selectedTags.contains(option) ? 1.05 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if !searchText.isEmpty && filteredOptions.isEmpty {
                Text("No \(title.lowercased()) found matching '\(searchText)'")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
    }
}

// MARK: - Tag Display View
struct TagDisplayView: View {
    let title: String
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(tags.count) tags")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if tags.isEmpty {
                Text("No \(title.lowercased()) added yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
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
            }
        }
    }
}

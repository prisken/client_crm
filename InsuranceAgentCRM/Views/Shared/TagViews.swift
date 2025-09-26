import SwiftUI

// MARK: - Tag Selection View
struct TagSelectionView: View {
    let title: String
    let options: [String]
    @Binding var selectedTags: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        if selectedTags.contains(option) {
                            selectedTags.remove(option)
                        } else {
                            selectedTags.insert(option)
                        }
                    }) {
                        Text(option)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedTags.contains(option) ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedTags.contains(option) ? .white : .primary)
                            .cornerRadius(16)
                    }
                }
            }
        }
    }
}

// MARK: - Tag Display View
struct TagDisplayView: View {
    let title: String
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(16)
                }
            }
        }
    }
}

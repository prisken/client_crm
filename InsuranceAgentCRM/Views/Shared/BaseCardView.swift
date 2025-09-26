import SwiftUI

// MARK: - Base Card View Protocol
protocol CardViewProtocol {
    var isEditMode: Bool { get }
    var onDelete: () -> Void { get }
    var onEdit: () -> Void { get }
}

// MARK: - Base Card View
struct BaseCardView<Content: View>: View {
    let isEditMode: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    @ViewBuilder let content: () -> Content
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                content()
                
                if isEditMode {
                    HStack(spacing: 8) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .confirmationDialog("Delete Item", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this item? This action cannot be undone.")
        }
    }
}

// MARK: - Card Content Components
struct CardTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
    }
}

struct CardAmount: View {
    let amount: Double
    let color: Color
    
    var body: some View {
        Text("$\(amount, specifier: "%.2f")")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
    }
}

struct CardDescription: View {
    let description: String?
    
    var body: some View {
        if let description = description, !description.isEmpty {
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
}

struct CardStatusBadge: View {
    let status: String
    let color: Color
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(4)
    }
}

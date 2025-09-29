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
        .confirmationDialog(
            type: .deleteItem,
            isPresented: $showingDeleteConfirmation,
            onConfirm: onDelete
        )
    }
}

// MARK: - Card Content Components (moved to CommonComponents)
// All card components are now available in CommonComponents.swift

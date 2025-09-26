import SwiftUI

// MARK: - Asset Card View
struct AssetCardView: View {
    let asset: Asset
    let isEditMode: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.name ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(asset.type ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(asset.amount?.doubleValue ?? 0, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    if let description = asset.assetDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                if isEditMode {
                    HStack(spacing: 8) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        Button(action: onDelete) {
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
    }
}

// MARK: - Expense Card View
struct ExpenseCardView: View {
    let expense: Expense
    let isEditMode: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(expense.name ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(expense.type ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(expense.frequency ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("$\(expense.amount?.doubleValue ?? 0, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    if let description = expense.assetDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                if isEditMode {
                    HStack(spacing: 8) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        Button(action: onDelete) {
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
    }
}

// MARK: - Product Card View
struct ProductCardView: View {
    let product: ClientProduct
    let isEditMode: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name ?? "")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(product.category ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(product.status ?? "")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    HStack {
                        Text("Amount: $\(product.amount?.doubleValue ?? 0, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Premium: $\(product.premium?.doubleValue ?? 0, specifier: "%.2f")")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    if let coverage = product.coverage, !coverage.isEmpty {
                        Text("Coverage: \(coverage)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let description = product.assetDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                if isEditMode {
                    HStack(spacing: 8) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .foregroundColor(.blue)
                        }
                        Button(action: onDelete) {
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
    }
    
    private var statusColor: Color {
        switch product.status?.lowercased() {
        case "active":
            return .green
        case "approved":
            return .blue
        case "proposed":
            return .orange
        case "under review":
            return .yellow
        case "cancelled":
            return .red
        case "expired":
            return .gray
        default:
            return .secondary
        }
    }
}

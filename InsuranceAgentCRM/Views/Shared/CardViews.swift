import SwiftUI

// MARK: - Asset Card View
struct AssetCardView: View {
    let asset: Asset
    let isEditMode: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        BaseCardView(
            isEditMode: isEditMode,
            onDelete: onDelete,
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 4) {
                CardTitle(title: asset.name ?? "")
                
                HStack {
                    Text(asset.type ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    CardAmount(amount: asset.amount?.doubleValue ?? 0, color: .green)
                }
                
                CardDescription(description: asset.assetDescription)
            }
        }
    }
}

// MARK: - Expense Card View
struct ExpenseCardView: View {
    let expense: Expense
    let isEditMode: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        BaseCardView(
            isEditMode: isEditMode,
            onDelete: onDelete,
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 4) {
                CardTitle(title: expense.name ?? "")
                
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
                    CardAmount(amount: expense.amount?.doubleValue ?? 0, color: .red)
                }
                
                CardDescription(description: expense.assetDescription)
            }
        }
    }
}

// MARK: - Product Card View
struct ProductCardView: View {
    let product: ClientProduct
    let isEditMode: Bool
    let onDelete: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        BaseCardView(
            isEditMode: isEditMode,
            onDelete: onDelete,
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 4) {
                CardTitle(title: product.name ?? "")
                
                HStack {
                    Text(product.category ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    CardStatusBadge(status: product.status ?? "", color: statusColor)
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
                
                CardDescription(description: product.assetDescription)
            }
        }
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

import SwiftUI

// MARK: - Asset Card View
struct AssetCardView: View {
    let asset: Asset
    let isEditMode: Bool
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(asset.type ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("$\(asset.amount?.doubleValue ?? 0, specifier: "%.2f")")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            Spacer()
            if isEditMode {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(expense.type ?? "") - \(expense.frequency ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("$\(expense.amount?.doubleValue ?? 0, specifier: "%.2f")")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }
            Spacer()
            if isEditMode {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name ?? "")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Amount: $\(product.amount?.doubleValue ?? 0, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Premium: $\(product.premium?.doubleValue ?? 0, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            Spacer()
            if isEditMode {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

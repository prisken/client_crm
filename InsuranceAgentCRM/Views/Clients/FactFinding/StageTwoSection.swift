import SwiftUI
import CoreData

// MARK: - Stage Two: Fact Finding
struct StageTwoSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = FactFindingViewModel()
    @StateObject private var assetEditManager: AssetEditSheetManager
    @StateObject private var expenseEditManager: ExpenseEditSheetManager
    
    init(client: Client, isEditMode: Bool) {
        self.client = client
        self.isEditMode = isEditMode
        self._assetEditManager = StateObject(wrappedValue: AssetEditSheetManager(context: PersistenceController.shared.container.viewContext))
        self._expenseEditManager = StateObject(wrappedValue: ExpenseEditSheetManager(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stage Two: Fact Finding")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Assets Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Assets")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    if isEditMode {
                        Button("Add Asset") {
                            viewModel.showingAddAsset = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                
                if viewModel.assets.isEmpty {
                    Text("No assets recorded yet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(viewModel.assets) { asset in
                        AssetCardView(asset: asset, isEditMode: isEditMode, onDelete: {
                            deleteAsset(asset)
                        }, onEdit: {
                            assetEditManager.startEdit(for: asset)
                        })
                    }
                }
            }
            
            Divider()
            
            // Expenses Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Expenses")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    if isEditMode {
                        Button("Add Expense") {
                            viewModel.showingAddExpense = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                
                if viewModel.expenses.isEmpty {
                    Text("No expenses recorded yet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    ForEach(viewModel.expenses) { expense in
                        ExpenseCardView(expense: expense, isEditMode: isEditMode, onDelete: {
                            deleteExpense(expense)
                        }, onEdit: {
                            expenseEditManager.startEdit(for: expense)
                        })
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            viewModel.loadData(client: client, context: viewContext)
        }
        .onChange(of: isEditMode) { oldValue, newValue in
            if newValue {
                print("🔧 DEBUG: Edit mode activated for Stage Two - reloading data")
                viewModel.loadData(client: client, context: viewContext)
            }
        }
        .onChange(of: client.id) { _, _ in
            viewModel.loadData(client: client, context: viewContext)
        }
        .sheet(isPresented: $viewModel.showingAddAsset) {
            AddAssetSheet(client: client, context: viewContext, onSave: {
                viewModel.loadData(client: client, context: viewContext)
            })
        }
        .sheet(isPresented: $viewModel.showingAddExpense) {
            AddExpenseSheet(client: client, context: viewContext, onSave: {
                viewModel.loadData(client: client, context: viewContext)
            })
        }
        .sheet(isPresented: $assetEditManager.showingEditAsset) {
            if let asset = assetEditManager.selectedAsset {
                EditAssetSheet(asset: asset, onSave: {
                    viewModel.loadData(client: client, context: viewContext)
                    assetEditManager.dismissEdit()
                })
            } else {
                ErrorSheet(message: "Asset not found", onDismiss: assetEditManager.dismissEdit)
            }
        }
        .sheet(isPresented: $expenseEditManager.showingEditExpense) {
            if let expense = expenseEditManager.selectedExpense {
                EditExpenseSheet(expense: expense, onSave: {
                    viewModel.loadData(client: client, context: viewContext)
                    expenseEditManager.dismissEdit()
                })
            } else {
                ErrorSheet(message: "Expense not found", onDismiss: expenseEditManager.dismissEdit)
            }
        }
    }
    
    private func deleteAsset(_ asset: Asset) {
        viewContext.delete(asset)
        do {
            try viewContext.save()
            viewModel.loadData(client: client, context: viewContext)
        } catch {
            print("Error deleting asset: \(error)")
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        viewContext.delete(expense)
        do {
            try viewContext.save()
            viewModel.loadData(client: client, context: viewContext)
        } catch {
            print("Error deleting expense: \(error)")
        }
    }
    
    
}

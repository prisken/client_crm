import SwiftUI
import CoreData

// MARK: - Stage Two: Fact Finding
struct StageTwoSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = FactFindingViewModel()
    @State private var selectedAssetID: UUID?
    @State private var selectedExpenseID: UUID?
    @State private var showingEditAsset = false
    @State private var showingEditExpense = false
    
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
                            print("🔧 DEBUG: Asset edit button clicked - Asset: \(asset.name ?? "nil"), ID: \(asset.id?.uuidString ?? "nil")")
                            print("🔧 DEBUG: Asset context: \(asset.managedObjectContext != nil ? "valid" : "nil")")
                            selectedAssetID = asset.id
                            print("🔧 DEBUG: selectedAssetID set to \(asset.id?.uuidString ?? "nil"), showingEditAsset = true")
                            showingEditAsset = true
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
                            print("🔧 DEBUG: Expense edit button clicked - Expense: \(expense.name ?? "nil"), ID: \(expense.id?.uuidString ?? "nil")")
                            print("🔧 DEBUG: Expense context: \(expense.managedObjectContext != nil ? "valid" : "nil")")
                            selectedExpenseID = expense.id
                            print("🔧 DEBUG: selectedExpenseID set to \(expense.id?.uuidString ?? "nil"), showingEditExpense = true")
                            showingEditExpense = true
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
        .sheet(isPresented: $showingEditAsset) {
            if let assetID = selectedAssetID,
               let asset = viewModel.assets.first(where: { $0.id == assetID }) {
                EditAssetSheet(asset: asset, onSave: {
                    print("🔧 DEBUG: EditAssetSheet onSave called")
                    viewModel.loadData(client: client, context: viewContext)
                })
            } else {
                // Fallback view if asset is not found
                VStack {
                    Text("Asset not found")
                        .font(.title2)
                    Text("Please try again")
                        .foregroundColor(.secondary)
                }
                .padding()
                .onAppear {
                    print("❌ DEBUG: Asset not found in sheet presentation - ID: \(selectedAssetID?.uuidString ?? "nil")")
                }
            }
        }
        .sheet(isPresented: $showingEditExpense) {
            if let expenseID = selectedExpenseID,
               let expense = viewModel.expenses.first(where: { $0.id == expenseID }) {
                EditExpenseSheet(expense: expense, onSave: {
                    print("🔧 DEBUG: EditExpenseSheet onSave called")
                    viewModel.loadData(client: client, context: viewContext)
                })
            } else {
                // Fallback view if expense is not found
                VStack {
                    Text("Expense not found")
                        .font(.title2)
                    Text("Please try again")
                        .foregroundColor(.secondary)
                }
                .padding()
                .onAppear {
                    print("❌ DEBUG: Expense not found in sheet presentation - ID: \(selectedExpenseID?.uuidString ?? "nil")")
                }
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

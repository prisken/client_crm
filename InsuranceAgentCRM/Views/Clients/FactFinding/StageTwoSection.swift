import SwiftUI
import CoreData

// MARK: - Stage Two: Fact Finding
struct StageTwoSection: View {
    let client: Client
    let isEditMode: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = FactFindingViewModel()
    @State private var selectedAsset: Asset?
    @State private var selectedExpense: Expense?
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
                            selectedAsset = asset
                            print("🔧 DEBUG: selectedAsset set, showingEditAsset = true")
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
                            selectedExpense = expense
                            print("🔧 DEBUG: selectedExpense set, showingEditExpense = true")
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
            if let asset = selectedAsset {
                EditAssetSheet(asset: asset, onSave: {
                    print("🔧 DEBUG: EditAssetSheet onSave called")
                    viewModel.loadData(client: client, context: viewContext)
                })
            } else {
                // Fallback view if asset is nil
                VStack {
                    Text("Asset not found")
                        .font(.title2)
                    Text("Please try again")
                        .foregroundColor(.secondary)
                }
                .padding()
                .onAppear {
                    print("❌ DEBUG: Asset is nil in sheet presentation")
                }
            }
        }
        .sheet(isPresented: $showingEditExpense) {
            if let expense = selectedExpense {
                EditExpenseSheet(expense: expense, onSave: {
                    print("🔧 DEBUG: EditExpenseSheet onSave called")
                    viewModel.loadData(client: client, context: viewContext)
                })
            } else {
                // Fallback view if expense is nil
                VStack {
                    Text("Expense not found")
                        .font(.title2)
                    Text("Please try again")
                        .foregroundColor(.secondary)
                }
                .padding()
                .onAppear {
                    print("❌ DEBUG: Expense is nil in sheet presentation")
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

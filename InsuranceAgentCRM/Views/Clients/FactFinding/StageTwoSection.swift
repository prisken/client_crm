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
    @State private var selectedAsset: Asset?
    @State private var selectedExpense: Expense?
    
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
                            
                            // Immediately fetch the asset to avoid timing issues
                            if let assetID = asset.id {
                                selectedAsset = fetchAsset(by: assetID)
                                print("🔧 DEBUG: Immediate fetch result - Asset: \(selectedAsset?.name ?? "nil"), Found: \(selectedAsset != nil)")
                                print("🔧 DEBUG: selectedAsset state after fetch: \(selectedAsset?.name ?? "nil"), context: \(selectedAsset?.managedObjectContext != nil ? "valid" : "nil")")
                            }
                            
                            print("🔧 DEBUG: selectedAssetID set to \(asset.id?.uuidString ?? "nil"), selectedAsset cached, showingEditAsset = true")
                            print("🔧 DEBUG: About to set showingEditAsset = true, selectedAsset is: \(selectedAsset?.name ?? "nil")")
                            showingEditAsset = true
                            print("🔧 DEBUG: showingEditAsset set to true, selectedAsset is still: \(selectedAsset?.name ?? "nil")")
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
                            
                            // Immediately fetch the expense to avoid timing issues
                            if let expenseID = expense.id {
                                selectedExpense = fetchExpense(by: expenseID)
                                print("🔧 DEBUG: Immediate fetch result - Expense: \(selectedExpense?.name ?? "nil"), Found: \(selectedExpense != nil)")
                                print("🔧 DEBUG: selectedExpense state after fetch: \(selectedExpense?.name ?? "nil"), context: \(selectedExpense?.managedObjectContext != nil ? "valid" : "nil")")
                            }
                            
                            print("🔧 DEBUG: selectedExpenseID set to \(expense.id?.uuidString ?? "nil"), selectedExpense cached, showingEditExpense = true")
                            print("🔧 DEBUG: About to set showingEditExpense = true, selectedExpense is: \(selectedExpense?.name ?? "nil")")
                            showingEditExpense = true
                            print("🔧 DEBUG: showingEditExpense set to true, selectedExpense is still: \(selectedExpense?.name ?? "nil")")
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
        .onChange(of: selectedAsset) { oldValue, newValue in
            print("🔧 DEBUG: selectedAsset changed from '\(oldValue?.name ?? "nil")' to '\(newValue?.name ?? "nil")'")
        }
        .onChange(of: selectedExpense) { oldValue, newValue in
            print("🔧 DEBUG: selectedExpense changed from '\(oldValue?.name ?? "nil")' to '\(newValue?.name ?? "nil")'")
        }
        .onChange(of: showingEditAsset) { oldValue, newValue in
            print("🔧 DEBUG: showingEditAsset changed from \(oldValue) to \(newValue)")
            if newValue {
                print("🔧 DEBUG: showingEditAsset = true, selectedAsset is: \(selectedAsset?.name ?? "nil")")
            }
        }
        .onChange(of: showingEditExpense) { oldValue, newValue in
            print("🔧 DEBUG: showingEditExpense changed from \(oldValue) to \(newValue)")
            if newValue {
                print("🔧 DEBUG: showingEditExpense = true, selectedExpense is: \(selectedExpense?.name ?? "nil")")
            }
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
            // Force evaluation order to prevent timing issues
            let _ = print("🔧 Sheet presentation - showingEditAsset: \(showingEditAsset)")
            let _ = print("🔧 Sheet presentation - selectedAssetID: \(selectedAssetID?.uuidString ?? "nil")")
            let _ = print("🔧 Sheet presentation - selectedAsset: \(selectedAsset?.name ?? "nil")")
            let _ = print("🔧 Sheet presentation - selectedAsset context: \(selectedAsset?.managedObjectContext != nil ? "valid" : "nil")")
            let _ = print("🔧 Sheet presentation - selectedAsset is nil: \(selectedAsset == nil)")
            
            if let asset = selectedAsset {
                let _ = print("🔧 Sheet presentation - Using selectedAsset: \(asset.name ?? "nil")")
                EditAssetSheet(asset: asset, onSave: {
                    print("🔧 DEBUG: EditAssetSheet onSave called")
                    viewModel.loadData(client: client, context: viewContext)
                    selectedAssetID = nil
                    selectedAsset = nil
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
                    print("❌ DEBUG: Available assets in viewModel:")
                    for asset in viewModel.assets {
                        print("❌ DEBUG:   Asset: \(asset.name ?? "nil"), ID: \(asset.id?.uuidString ?? "nil")")
                    }
                    print("❌ DEBUG: Total assets count: \(viewModel.assets.count)")
                }
            }
        }
        .sheet(isPresented: $showingEditExpense) {
            // Force evaluation order to prevent timing issues
            let _ = print("🔧 Sheet presentation - showingEditExpense: \(showingEditExpense)")
            let _ = print("🔧 Sheet presentation - selectedExpenseID: \(selectedExpenseID?.uuidString ?? "nil")")
            let _ = print("🔧 Sheet presentation - selectedExpense: \(selectedExpense?.name ?? "nil")")
            let _ = print("🔧 Sheet presentation - selectedExpense context: \(selectedExpense?.managedObjectContext != nil ? "valid" : "nil")")
            let _ = print("🔧 Sheet presentation - selectedExpense is nil: \(selectedExpense == nil)")
            
            if let expense = selectedExpense {
                let _ = print("🔧 Sheet presentation - Using selectedExpense: \(expense.name ?? "nil")")
                EditExpenseSheet(expense: expense, onSave: {
                    print("🔧 DEBUG: EditExpenseSheet onSave called")
                    viewModel.loadData(client: client, context: viewContext)
                    selectedExpenseID = nil
                    selectedExpense = nil
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
                    print("❌ DEBUG: Available expenses in viewModel:")
                    for expense in viewModel.expenses {
                        print("❌ DEBUG:   Expense: \(expense.name ?? "nil"), ID: \(expense.id?.uuidString ?? "nil")")
                    }
                    print("❌ DEBUG: Total expenses count: \(viewModel.expenses.count)")
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
    
    // Helper functions to fetch fresh objects by ID
    private func fetchAsset(by id: UUID) -> Asset? {
        print("🔧 DEBUG: fetchAsset called with ID: \(id.uuidString)")
        let request: NSFetchRequest<Asset> = Asset.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let assets = try viewContext.fetch(request)
            print("🔧 DEBUG: CoreData fetch returned \(assets.count) assets")
            if let asset = assets.first {
                print("🔧 DEBUG: Found asset: \(asset.name ?? "nil"), ID: \(asset.id?.uuidString ?? "nil")")
            } else {
                print("❌ DEBUG: No asset found with ID: \(id.uuidString)")
            }
            return assets.first
        } catch {
            print("❌ DEBUG: Error fetching asset: \(error)")
            return nil
        }
    }
    
    private func fetchExpense(by id: UUID) -> Expense? {
        print("🔧 DEBUG: fetchExpense called with ID: \(id.uuidString)")
        let request: NSFetchRequest<Expense> = Expense.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let expenses = try viewContext.fetch(request)
            print("🔧 DEBUG: CoreData fetch returned \(expenses.count) expenses")
            if let expense = expenses.first {
                print("🔧 DEBUG: Found expense: \(expense.name ?? "nil"), ID: \(expense.id?.uuidString ?? "nil")")
            } else {
                print("❌ DEBUG: No expense found with ID: \(id.uuidString)")
            }
            return expenses.first
        } catch {
            print("❌ DEBUG: Error fetching expense: \(error)")
            return nil
        }
    }
    
}

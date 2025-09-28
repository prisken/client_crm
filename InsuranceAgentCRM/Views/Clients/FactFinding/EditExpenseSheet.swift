import SwiftUI
import CoreData

// MARK: - Edit Expense Sheet
struct EditExpenseSheet: View {
    let expense: Expense
    let onSave: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var type: String = "Fixed"
    @State private var amount: String = ""
    @State private var frequency: String = "monthly"
    @State private var description: String = ""
    
    var body: some View {
        BaseEditSheet(
            title: "Edit Expense",
            onSave: {
                saveExpense()
            }
        ) {
            Section("Expense Details") {
                FormTextField(title: "Expense Name", text: $name)
                
                FormPicker(
                    title: "Expense Type",
                    selection: $type,
                    options: FormConstants.expenseTypes
                )
                
                FormTextField(
                    title: "Amount",
                    text: $amount,
                    keyboardType: .decimalPad
                )
                
                FormPicker(
                    title: "Frequency",
                    selection: $frequency,
                    options: FormConstants.expenseFrequencies
                )
                
                FormTextEditor(
                    title: "Description (Optional)",
                    text: $description
                )
            }
        }
        .onAppear {
            print("🔧 DEBUG: EditExpenseSheet onAppear called")
            print("🔧 DEBUG: Expense in sheet - Name: \(expense.name ?? "nil"), ID: \(expense.id?.uuidString ?? "nil")")
            print("🔧 DEBUG: Expense context: \(expense.managedObjectContext != nil ? "valid" : "nil")")
            // Load data immediately when sheet appears
            loadExpenseData()
        }
        .onChange(of: expense.id) { _, _ in
            // Reload data if expense changes
            loadExpenseData()
        }
    }
    
    private func loadExpenseData() {
        print("🔧 DEBUG: loadExpenseData called")
        print("🔧 DEBUG: Expense before refresh - Name: \(expense.name ?? "nil"), Context: \(expense.managedObjectContext != nil ? "valid" : "nil")")
        
        // Refresh the expense from context to ensure it's valid
        viewContext.refresh(expense, mergeChanges: true)
        
        print("🔧 DEBUG: Expense after refresh - Name: \(expense.name ?? "nil"), Context: \(expense.managedObjectContext != nil ? "valid" : "nil")")
        
        name = expense.name ?? ""
        type = expense.type ?? "Fixed"
        amount = String(expense.amount?.doubleValue ?? 0)
        frequency = expense.frequency ?? "monthly"
        description = expense.assetDescription ?? ""
        
        print("🔧 DEBUG: Expense data loaded - name: \(name), type: \(type), amount: \(amount), frequency: \(frequency)")
    }
    
    private func saveExpense() {
        expense.name = name
        expense.type = type
        expense.amount = NSDecimalNumber(string: amount.isEmpty ? "0" : amount)
        expense.frequency = frequency
        expense.assetDescription = description.isEmpty ? nil : description
        expense.updatedAt = Date()
        
        do {
            try viewContext.save()
            onSave()
        } catch {
            print("Error saving expense: \(error)")
        }
    }
}

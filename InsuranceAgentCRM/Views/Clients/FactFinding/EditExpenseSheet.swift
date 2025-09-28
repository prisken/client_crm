import SwiftUI
import CoreData

// MARK: - Edit Expense Sheet
struct EditExpenseSheet: View {
    let expense: Expense
    let onSave: () -> Void
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var type: String = ""
    @State private var amount: String = ""
    @State private var frequency: String = ""
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
            // Ensure data is loaded when sheet appears
            DispatchQueue.main.async {
                loadExpenseData()
            }
        }
        .onChange(of: expense.id) { _, _ in
            // Reload data if expense changes
            loadExpenseData()
        }
    }
    
    private func loadExpenseData() {
        // Ensure we have a valid expense
        guard expense.managedObjectContext != nil else {
            print("Warning: Expense context is nil")
            return
        }
        
        name = expense.name ?? ""
        type = expense.type ?? ""
        amount = String(expense.amount?.doubleValue ?? 0)
        frequency = expense.frequency ?? ""
        description = expense.assetDescription ?? ""
        
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

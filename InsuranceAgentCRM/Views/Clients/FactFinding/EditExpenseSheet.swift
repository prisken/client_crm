import SwiftUI
import CoreData

// MARK: - Edit Expense Sheet
struct EditExpenseSheet: View {
    let expense: Expense
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var type: String = ""
    @State private var amount: String = ""
    @State private var frequency: String = ""
    @State private var description: String = ""
    
    private let expenseTypes = [
        "Housing", "Food", "Transportation", "Healthcare", "Education",
        "Entertainment", "Utilities", "Insurance", "Debt", "Other"
    ]
    
    private let frequencies = [
        "Daily", "Weekly", "Monthly", "Quarterly", "Yearly", "One-time"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Expense Details") {
                    TextField("Expense Name", text: $name)
                    
                    Picker("Expense Type", selection: $type) {
                        ForEach(expenseTypes, id: \.self) { expenseType in
                            Text(expenseType).tag(expenseType)
                        }
                    }
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencies, id: \.self) { freq in
                            Text(freq).tag(freq)
                        }
                    }
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty || type.isEmpty || amount.isEmpty || frequency.isEmpty)
                }
            }
        }
        .onAppear {
            loadExpenseData()
        }
    }
    
    private func loadExpenseData() {
        name = expense.name ?? ""
        type = expense.type ?? ""
        amount = String(expense.amount?.doubleValue ?? 0)
        frequency = expense.frequency ?? ""
        description = expense.assetDescription ?? ""
    }
    
    private func saveExpense() {
        expense.name = name
        expense.type = type
        expense.amount = NSDecimalNumber(string: amount)
        expense.frequency = frequency
        expense.assetDescription = description.isEmpty ? nil : description
        expense.updatedAt = Date()
        
        do {
            try viewContext.save()
            onSave()
            dismiss()
        } catch {
            print("Error saving expense: \(error)")
        }
    }
}

import SwiftUI
import CoreData

// MARK: - Base Edit Sheet Protocol
protocol EditSheetProtocol {
    func saveChanges()
    func loadData()
    var isValid: Bool { get }
}

// MARK: - Base Edit Sheet
struct BaseEditSheet<Content: View>: View {
    let title: String
    let onSave: () -> Void
    @ViewBuilder let content: () -> Content
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                content()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Common Form Components
struct FormTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    init(title: String, text: Binding<String>, placeholder: String = "", keyboardType: UIKeyboardType = .default) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        TextField(placeholder.isEmpty ? title : placeholder, text: $text)
            .keyboardType(keyboardType)
    }
}

struct FormPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    
    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.self) { option in
                Text(option).tag(option)
            }
        }
    }
}

struct FormTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let lineLimit: ClosedRange<Int>
    
    init(title: String, text: Binding<String>, placeholder: String = "", lineLimit: ClosedRange<Int> = 3...6) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        TextField(placeholder.isEmpty ? title : placeholder, text: $text, axis: .vertical)
            .lineLimit(lineLimit)
    }
}

// MARK: - Common Constants
struct FormConstants {
    static let assetTypes = [
        "Cash", "Savings Account", "Investment", "Property", "Vehicle", 
        "Jewelry", "Art", "Collectibles", "Business", "Insurance Policy", 
        "Fixed Asset", "Income", "Other"
    ]
    
    static let expenseTypes = [
        "Housing", "Food", "Transportation", "Healthcare", "Education",
        "Entertainment", "Utilities", "Insurance", "Debt", "Fixed", 
        "Monthly", "Variable", "Annual", "Other"
    ]
    
    static let expenseFrequencies = [
        "monthly", "quarterly", "annually", "one-time", "Monthly", "Quarterly", "Annually", "One-time", "Variable"
    ]
    
    static let productCategories = [
        "Life", "Life Insurance", "Health Insurance", "Medical", "Critical Illness", "Auto Insurance", "Home Insurance",
        "Investment", "Retirement", "Education", "General Insurance", "Savings", "Other"
    ]
    
    static let productStatuses = [
        "Proposed", "Under Review", "Approved", "Active", "Cancelled", "Expired"
    ]
}

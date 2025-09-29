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
            KeyboardAwareForm {
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

// MARK: - Form Constants (moved to AppConstants)
// All form constants are now available through AppConstants.Form

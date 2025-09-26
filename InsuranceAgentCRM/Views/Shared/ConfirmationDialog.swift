import SwiftUI

// MARK: - Confirmation Dialog Types
enum ConfirmationType {
    case deleteItem
    case deleteClient
    case deleteTask
    case deleteRemark
    case deleteTag
    case deleteRelationship
    
    var title: String {
        switch self {
        case .deleteItem: return "Delete Item"
        case .deleteClient: return "Delete Client"
        case .deleteTask: return "Delete Task"
        case .deleteRemark: return "Delete Remark"
        case .deleteTag: return "Delete Tag"
        case .deleteRelationship: return "Delete Relationship"
        }
    }
    
    var message: String {
        switch self {
        case .deleteItem: return "Are you sure you want to delete this item? This action cannot be undone."
        case .deleteClient: return "Are you sure you want to delete this client? This action cannot be undone and will remove all associated data."
        case .deleteTask: return "Are you sure you want to delete this task? This action cannot be undone."
        case .deleteRemark: return "Are you sure you want to delete this remark? This action cannot be undone."
        case .deleteTag: return "Are you sure you want to delete this tag? This action cannot be undone and will remove it from all clients."
        case .deleteRelationship: return "Are you sure you want to delete this relationship? This action cannot be undone."
        }
    }
}

// MARK: - Reusable Confirmation Dialog
struct ConfirmationDialog: ViewModifier {
    let type: ConfirmationType
    let isPresented: Binding<Bool>
    let onConfirm: () -> Void
    let customMessage: String?
    
    init(
        type: ConfirmationType,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void,
        customMessage: String? = nil
    ) {
        self.type = type
        self.isPresented = isPresented
        self.onConfirm = onConfirm
        self.customMessage = customMessage
    }
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog(type.title, isPresented: isPresented) {
                Button("Delete", role: .destructive, action: onConfirm)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(customMessage ?? type.message)
            }
    }
}

// MARK: - View Extension
extension View {
    func confirmationDialog(
        type: ConfirmationType,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void,
        customMessage: String? = nil
    ) -> some View {
        self.modifier(ConfirmationDialog(
            type: type,
            isPresented: isPresented,
            onConfirm: onConfirm,
            customMessage: customMessage
        ))
    }
}

// MARK: - Specific Confirmation Dialogs
struct ClientConfirmationDialog: ViewModifier {
    let client: Client
    let isPresented: Binding<Bool>
    let onConfirm: () -> Void
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("Delete Client", isPresented: isPresented) {
                Button("Delete", role: .destructive, action: onConfirm)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete '\(client.firstName ?? "") \(client.lastName ?? "")'? This action cannot be undone and will remove all associated data.")
            }
    }
}

struct TaskConfirmationDialog: ViewModifier {
    let task: ClientTask
    let isPresented: Binding<Bool>
    let onConfirm: () -> Void
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("Delete Task", isPresented: isPresented) {
                Button("Delete", role: .destructive, action: onConfirm)
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete '\(task.title ?? "this task")'? This action cannot be undone.")
            }
    }
}

// MARK: - View Extensions for Specific Types
extension View {
    func clientConfirmationDialog(
        client: Client,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.modifier(ClientConfirmationDialog(
            client: client,
            isPresented: isPresented,
            onConfirm: onConfirm
        ))
    }
    
    func taskConfirmationDialog(
        task: ClientTask,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.modifier(TaskConfirmationDialog(
            task: task,
            isPresented: isPresented,
            onConfirm: onConfirm
        ))
    }
}

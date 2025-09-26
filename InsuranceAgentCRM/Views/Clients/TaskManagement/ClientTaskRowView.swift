import SwiftUI

// MARK: - Client Task Row View
struct ClientTaskRowView: View {
    let task: ClientTask
    let isCollapsed: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onCollapse: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onToggle) {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(task.isCompleted ? .green : .gray)
                        .font(.title3)
                        .frame(width: 24, height: 24)
                        .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                }
                .buttonStyle(PlainButtonStyle())
                .help(task.isCompleted ? "Mark as incomplete" : "Mark as complete")
                
                Text(task.title ?? "")
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .animation(.easeInOut(duration: 0.2), value: task.isCompleted)
                
                Spacer()
                
                Button(action: onCollapse) {
                    Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                        .foregroundColor(.secondary)
                        .font(.title3)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(PlainButtonStyle())
                .help(isCollapsed ? "Expand details" : "Collapse details")
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title3)
                        .frame(width: 24, height: 24)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Delete task")
            }
            
            if !isCollapsed {
                HStack {
                    Text("Created: \(task.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Client Task Sheet
struct AddClientTaskSheet: View {
    @Binding var newTaskTitle: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Task Title", text: $newTaskTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Add Task")
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
                    .disabled(newTaskTitle.isEmpty)
                }
            }
        }
    }
}

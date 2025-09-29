import SwiftUI
import CoreData

// MARK: - Task Checklist Section
struct TaskChecklistSection: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var newTaskTitle = ""
    @State private var showingAddTask = false
    @State private var collapsedTasks: Set<UUID> = []
    @State private var taskToDelete: ClientTask?
    @State private var showingDeleteConfirmation = false

    // Use Core Data-driven fetch that auto-updates UI for this client's tasks
    @FetchRequest var tasks: FetchedResults<ClientTask>

    init(client: Client) {
        self.client = client
        // Build a fetch request scoped to this client
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \ClientTask.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \ClientTask.createdAt, ascending: false)
        ]
        _tasks = FetchRequest(
            sortDescriptors: sortDescriptors,
            predicate: NSPredicate(format: "client == %@", client)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Task Checklist")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("Add Task") {
                    showingAddTask = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if tasks.isEmpty {
                Text("No tasks yet. Add your first task!")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        ClientTaskRowView(
                            task: task,
                            isCollapsed: collapsedTasks.contains(task.id ?? UUID()),
                            onToggle: { toggleTask(task) },
                            onDelete: { confirmDeleteTask(task) },
                            onCollapse: { toggleCollapse(task.id ?? UUID()) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingAddTask) {
            AddClientTaskSheet(newTaskTitle: $newTaskTitle, onSave: addTask)
        }
        .confirmationDialog(
            "Delete Task",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let task = taskToDelete {
                    deleteTask(task)
                }
            }
            Button("Cancel", role: .cancel) {
                taskToDelete = nil
            }
        } message: {
            if let task = taskToDelete {
                Text("Are you sure you want to delete '\(task.title ?? "")' for \(client.firstName ?? "") \(client.lastName ?? "")? This action cannot be undone.")
            }
        }
    }
    
    private func toggleTask(_ task: ClientTask) {
        withAnimation {
            task.isCompleted.toggle()
            task.updatedAt = Date()
        }
        do {
            try viewContext.save()
            
            // Sync to Firebase
            firebaseManager.syncTask(task)
            
            logInfo("Task toggled successfully")
        } catch {
            logError("Error updating task: \(error.localizedDescription)")
        }
    }
    
    private func confirmDeleteTask(_ task: ClientTask) {
        taskToDelete = task
        showingDeleteConfirmation = true
    }
    
    private func deleteTask(_ task: ClientTask) {
        logInfo("Deleting task: \(task.title ?? "") for client: \(client.firstName ?? "") \(client.lastName ?? "")")
        
        taskToDelete = nil
        
        // Delete from Firebase first
        firebaseManager.deleteTask(task)
        
        withAnimation {
            viewContext.delete(task)
        }
        
        do {
            try viewContext.save()
            logInfo("Task deleted successfully")
        } catch {
            logError("Error deleting task: \(error.localizedDescription)")
        }
    }
    
    private func toggleCollapse(_ taskId: UUID) {
        if collapsedTasks.contains(taskId) {
            collapsedTasks.remove(taskId)
        } else {
            collapsedTasks.insert(taskId)
        }
    }
    
    private func addTask() {
        guard !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let taskTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        logInfo("Adding task '\(taskTitle)' for client: \(client.firstName ?? "") \(client.lastName ?? "") (ID: \(client.id?.uuidString ?? "nil"))")
        
        let task = ClientTask(context: viewContext)
        task.id = UUID()
        task.title = taskTitle
        task.isCompleted = false
        task.createdAt = Date()
        task.updatedAt = Date()
        task.client = client
        
        newTaskTitle = ""
        
        withAnimation {
            // The task is already added to the context, animation will handle the UI update
        }
        
        do {
            try viewContext.save()
            
            // Sync to Firebase
            firebaseManager.syncTask(task)
            
            logInfo("Task added successfully for client: \(client.firstName ?? "") \(client.lastName ?? "") (ID: \(client.id?.uuidString ?? "nil"))")
        } catch {
            logError("Error adding task: \(error.localizedDescription)")
            newTaskTitle = taskTitle
        }
    }
}

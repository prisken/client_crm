import SwiftUI
import CoreData

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingAddTask = false
    @State private var selectedTask: ClientTask?
    @State private var searchText = ""
    @State private var collapsedDoneTasks = true

    // Live-updating list of tasks for current user's clients
    @FetchRequest private var allTasks: FetchedResults<ClientTask>

    init() {
        // Default fetch: all tasks; we will filter in-memory for search and sectioning
        let sortDescriptors = [
            NSSortDescriptor(keyPath: \ClientTask.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \ClientTask.createdAt, ascending: false)
        ]
        _allTasks = FetchRequest(sortDescriptors: sortDescriptors)
    }
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
        
        var predicate: NSPredicate {
            switch self {
            case .all:
                return NSPredicate(value: true)
            case .pending:
                return NSPredicate(format: "isCompleted == NO")
            case .completed:
                return NSPredicate(format: "isCompleted == YES")
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Collapse Done Tasks Toggle
                if selectedFilter == .all {
                    HStack {
                        Button(action: { collapsedDoneTasks.toggle() }) {
                            HStack {
                                Image(systemName: collapsedDoneTasks ? "chevron.right" : "chevron.down")
                                Text("Collapse Done Tasks")
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .foregroundColor(.blue)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                
                // Tasks List
                if filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: "checklist",
                        title: selectedFilter == .all ? "No Tasks" : "No \(selectedFilter.rawValue) Tasks",
                        subtitle: selectedFilter == .all ? "Create your first task to get started" : "No tasks match this filter"
                    )
                } else {
                    List(selection: $selectedTask) {
                        ForEach(displayedTasks) { task in
                            TasksViewTaskRow(task: task) {
                                toggleTaskCompletion(task)
                            }
                            .tag(task)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                BulkTaskCreationView()
            }
        } detail: {
            if let selectedTask = selectedTask {
                ClientTaskDetailView(task: selectedTask)
                    .id(selectedTask.id) // Ensure unique view for each task
            } else {
                VStack {
                    Image(systemName: "doc.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("Select a task to view details")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            // Fetch from Firebase first
            firebaseManager.fetchAllData(context: viewContext)
        }
        // No manual loads needed; @FetchRequest autoupdates
    }
    
    private var filteredTasks: [ClientTask] {
        // Filter by current user's clients if available
        let userFiltered = allTasks.filter { task in
            guard let user = authManager.currentUser else { return true }
            return task.client?.owner == user
        }
        // Apply tab filter
        let statusFiltered = userFiltered.filter { task in
            selectedFilter.predicate.evaluate(with: task)
        }
        // Apply search
        if searchText.isEmpty { return statusFiltered }
        let lower = searchText.lowercased()
        return statusFiltered.filter { task in
            let title = task.title?.lowercased() ?? ""
            let first = task.client?.firstName?.lowercased() ?? ""
            let last = task.client?.lastName?.lowercased() ?? ""
            return title.contains(lower) || first.contains(lower) || last.contains(lower)
        }
    }
    
    private var displayedTasks: [ClientTask] {
        if selectedFilter == .all && collapsedDoneTasks {
            return filteredTasks.filter { !$0.isCompleted }
        }
        return filteredTasks
    }
    
    private func toggleTaskCompletion(_ task: ClientTask) {
        withAnimation {
            task.isCompleted.toggle()
            task.updatedAt = Date()
            
            do {
                try viewContext.save()
                
                // Sync task to Firebase
                firebaseManager.syncTask(task)
            } catch {
                print("Error updating task: \(error)")
            }
        }
    }
    
    private func deleteTasks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let task = filteredTasks[index]
                viewContext.delete(task)
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }
}

// MARK: - Tasks View Task Row
struct TasksViewTaskRow: View {
    let task: ClientTask
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            // Completion checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .font(.headline)
                    .strikethrough(task.isCompleted)
                
                if let client = task.client {
                    Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let createdAt = task.createdAt {
                    Text("Created \(createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Task metadata
            VStack(alignment: .trailing, spacing: 4) {
                if task.isCompleted {
                    Text("✓ Done")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                } else {
                    Text("Pending")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
                
                if task.isCompleted, let updatedAt = task.updatedAt {
                    Text("Completed \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var priority: Int16 = 1
    @State private var selectedClient: Client?
    @State private var selectedStage: FollowUpStage?
    @State private var effortHours: Double = 1.0
    @State private var estimatedCommission: Decimal = 0
    @State private var probability: Double = 0.5
    
    @State private var clients: [Client] = []
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FollowUpStage.order, ascending: true)]
    ) private var stages: FetchedResults<FollowUpStage>
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $title)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Scheduling") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Priority", selection: $priority) {
                        Text("Low").tag(Int16(0))
                        Text("Medium").tag(Int16(1))
                        Text("High").tag(Int16(2))
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Client & Stage") {
                    Picker("Client", selection: $selectedClient) {
                        Text("Select Client").tag(nil as Client?)
                        ForEach(clients, id: \.self) { client in
                            Text("\(client.firstName ?? "") \(client.lastName ?? "")").tag(client as Client?)
                        }
                    }
                    
                    Picker("Follow-up Stage", selection: $selectedStage) {
                        Text("Select Stage").tag(nil as FollowUpStage?)
                        ForEach(stages, id: \.self) { stage in
                            Text(stage.name ?? "").tag(stage as FollowUpStage?)
                        }
                    }
                }
                
                Section("Commission Optimization") {
                    HStack {
                        Text("Effort Hours")
                        Spacer()
                        TextField("Hours", value: $effortHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Estimated Commission")
                        Spacer()
                        TextField("Amount", value: $estimatedCommission, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Probability of Success")
                        Slider(value: $probability, in: 0...1, step: 0.1)
                        Text("\(Int(probability * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
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
                        saveTask()
                    }
                    .disabled(title.isEmpty || selectedClient == nil)
                }
            }
        }
        .onAppear {
            loadClients()
        }
    }
    
    private func loadClients() {
        guard let currentUser = authManager.currentUser else { return }
        
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.predicate = NSPredicate(format: "owner == %@", currentUser)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Client.lastName, ascending: true),
            NSSortDescriptor(keyPath: \Client.firstName, ascending: true)
        ]
        
        do {
            clients = try viewContext.fetch(request)
            print("🔍 Loaded \(clients.count) clients for current user")
        } catch {
            print("❌ Error loading clients: \(error)")
        }
    }
    
    private func saveTask() {
        let task = Task(context: viewContext)
        task.id = UUID()
        task.title = title
        task.notes = notes.isEmpty ? nil : notes
        task.dueDate = dueDate
        task.priority = priority
        task.status = "pending"
        task.effortHours = effortHours
        task.estimatedCommission = NSDecimalNumber(decimal: estimatedCommission)
        task.probability = probability
        task.createdAt = Date()
        task.updatedAt = Date()
        task.client = selectedClient
        task.stage = selectedStage
        
        do {
            try viewContext.save()
            
            // Sync task to Firebase
            firebaseManager.syncStandaloneTask(task)
            
            dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}

// MARK: - Task Remark Manager
class TaskRemarkManager: ObservableObject {
    @Published var remarks: [TaskRemark] = []
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func loadRemarks(for task: ClientTask) {
        if let taskRemarks = task.remarks as? Set<TaskRemark> {
            remarks = Array(taskRemarks).sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
        } else {
            remarks = []
        }
    }
    
    func addRemark(content: String, to task: ClientTask) {
        let remark = TaskRemark(context: context)
        remark.id = UUID()
        remark.content = content
        remark.createdAt = Date()
        remark.updatedAt = Date()
        remark.task = task
        
        do {
            try context.save()
            loadRemarks(for: task)
            print("✅ New remark added to task: \(task.title ?? "Unknown")")
        } catch {
            print("❌ Error adding remark: \(error)")
        }
    }
    
    func updateRemark(_ remark: TaskRemark, newContent: String) {
        remark.content = newContent
        remark.updatedAt = Date()
        
        do {
            try context.save()
            print("✅ Remark updated: \(remark.content ?? "Unknown")")
        } catch {
            print("❌ Error updating remark: \(error)")
        }
    }
    
    func deleteRemark(_ remark: TaskRemark) {
        context.delete(remark)
        
        do {
            try context.save()
            print("✅ Remark deleted")
        } catch {
            print("❌ Error deleting remark: \(error)")
        }
    }
}

// MARK: - Client Task Detail View
struct ClientTaskDetailView: View {
    let task: ClientTask
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var remarkManager: TaskRemarkManager
    @State private var showingAddRemark = false
    @State private var newRemark = ""
    @State private var selectedRemark: TaskRemark?
    @State private var showingEditRemark = false
    @State private var editingRemark = ""
    
    init(task: ClientTask) {
        self.task = task
        self._remarkManager = StateObject(wrappedValue: TaskRemarkManager(context: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Task Header
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(task.title ?? "Untitled Task")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        StatusBadge(status: task.isCompleted ? "completed" : "pending")
                    }
                    
                    if let client = task.client {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                            Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                                .font(.headline)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Task Details
                VStack(alignment: .leading, spacing: 16) {
                    Text("Task Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    DetailRow(label: "Created", value: task.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")
                    DetailRow(label: "Status", value: task.isCompleted ? "Completed" : "Pending")
                    
                    if task.isCompleted, let updatedAt = task.updatedAt {
                        DetailRow(label: "Completed", value: updatedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                
                // Remarks Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Remarks & Follow-up")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("Add Remark") {
                            showingAddRemark = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    
                    if remarkManager.remarks.isEmpty {
                        Text("No remarks added yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(remarkManager.remarks) { remark in
                                NewRemarkRowView(
                                    remark: remark,
                                    onEdit: {
                                        selectedRemark = remark
                                        editingRemark = remark.content ?? ""
                                        showingEditRemark = true
                                    },
                                    onDelete: {
                                        remarkManager.deleteRemark(remark)
                                        remarkManager.loadRemarks(for: task)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            remarkManager.loadRemarks(for: task)
        }
        .id(task.id) // Ensure unique view for each task
        .sheet(isPresented: $showingAddRemark) {
            NewAddRemarkSheet(
                newRemark: $newRemark,
                onSave: {
                    remarkManager.addRemark(content: newRemark, to: task)
                    newRemark = ""
                }
            )
        }
        .sheet(isPresented: $showingEditRemark) {
            NewEditRemarkSheet(
                remark: $editingRemark,
                onSave: {
                    if let selectedRemark = selectedRemark {
                        remarkManager.updateRemark(selectedRemark, newContent: editingRemark)
                        remarkManager.loadRemarks(for: task)
                    }
                }
            )
        }
    }
    
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case "completed":
            return .green
        case "pending":
            return .orange
        case "overdue":
            return .red
        default:
            return .gray
        }
    }
}

struct PriorityText: View {
    let priority: Int
    
    var body: some View {
        Text(priorityName)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(priorityColor)
    }
    
    private var priorityName: String {
        switch priority {
        case 0: return "Low"
        case 1: return "Medium"
        case 2: return "High"
        default: return "Unknown"
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case 0: return .green
        case 1: return .orange
        case 2: return .red
        default: return .gray
        }
    }
}

private func priorityText(priority: Int) -> String {
    switch priority {
    case 0: return "Low"
    case 1: return "Medium"
    case 2: return "High"
    default: return "Unknown"
    }
}

// MARK: - New Remark Row View
struct NewRemarkRowView: View {
    let remark: TaskRemark
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(remark.content ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("Created: \(remark.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let updatedAt = remark.updatedAt, updatedAt != remark.createdAt {
                        Text("• Updated: \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .confirmationDialog("Delete Remark", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this remark?")
        }
    }
}

// MARK: - New Add Remark Sheet
struct NewAddRemarkSheet: View {
    @Binding var newRemark: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add New Remark")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                TextField("Enter your remark", text: $newRemark, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(5...10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Remark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onSave()
                        dismiss()
                    }
                    .disabled(newRemark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - New Edit Remark Sheet
struct NewEditRemarkSheet: View {
    @Binding var remark: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Remark")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                TextField("Edit your remark", text: $remark, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(5...10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Remark")
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
                    .disabled(remark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct AddRemarkSheet: View {
    @Binding var remarks: String
    @Binding var newRemark: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Existing remarks
                if !remarks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Existing Remarks")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ScrollView {
                            Text(remarks)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 150)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // New remark input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add New Remark")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Add a remark or follow-up note", text: $newRemark, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(5...10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Remark")
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
                    .disabled(newRemark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// Removed TasksViewModel – now driven entirely by @FetchRequest

#Preview {
    TasksView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager())
}


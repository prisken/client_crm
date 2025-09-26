import SwiftUI
import CoreData

struct TasksView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = TasksViewModel()
    @State private var selectedFilter: TaskFilter = .all
    @State private var showingAddTask = false
    
    enum TaskFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
        case overdue = "Overdue"
        
        var predicate: NSPredicate {
            switch self {
            case .all:
                return NSPredicate(value: true)
            case .pending:
                return NSPredicate(format: "status == %@", "pending")
            case .completed:
                return NSPredicate(format: "status == %@", "completed")
            case .overdue:
                return NSPredicate(format: "status == %@ AND dueDate < %@", "pending", Date() as NSDate)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filter Picker
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Tasks List
                if filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: "checklist",
                        title: selectedFilter == .all ? "No Tasks" : "No \(selectedFilter.rawValue) Tasks",
                        subtitle: selectedFilter == .all ? "Create your first task to get started" : "No tasks match this filter"
                    )
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            TaskRowView(task: task) {
                                toggleTaskCompletion(task)
                            }
                        }
                        .onDelete(perform: deleteTasks)
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
                AddTaskView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onAppear {
            viewModel.loadTasks(context: viewContext)
        }
        .onChange(of: selectedFilter) { _ in
            viewModel.loadTasks(context: viewContext, filter: selectedFilter)
        }
    }
    
    private var filteredTasks: [Task] {
        viewModel.tasks.filter { task in
            selectedFilter.predicate.evaluate(with: task)
        }
    }
    
    private func toggleTaskCompletion(_ task: Task) {
        withAnimation {
            if task.status == "completed" {
                task.status = "pending"
                task.completedAt = nil
            } else {
                task.status = "completed"
                task.completedAt = Date()
            }
            task.updatedAt = Date()
            
            do {
                try viewContext.save()
                viewModel.loadTasks(context: viewContext, filter: selectedFilter)
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
                viewModel.loadTasks(context: viewContext, filter: selectedFilter)
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }
}

struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            // Completion checkbox
            Button(action: onToggle) {
                Image(systemName: task.status == "completed" ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.status == "completed" ? .green : .secondary)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .font(.headline)
                    .strikethrough(task.status == "completed")
                
                if let client = task.client {
                    Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Task metadata
            VStack(alignment: .trailing, spacing: 4) {
                PriorityBadge(priority: Int(task.priority))
                
                Text(task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.caption)
                    .foregroundColor(dueDateColor)
                
                if task.status == "completed", let completedAt = task.completedAt {
                    Text("Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var dueDateColor: Color {
        guard let dueDate = task.dueDate else { return .secondary }
        
        if task.status == "completed" {
            return .green
        } else if dueDate < Date() {
            return .red
        } else if dueDate.timeIntervalSinceNow < 86400 { // Less than 24 hours
            return .orange
        } else {
            return .secondary
        }
    }
}

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager
    
    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var priority: Int16 = 1
    @State private var selectedClient: Client?
    @State private var selectedStage: FollowUpStage?
    @State private var effortHours: Double = 1.0
    @State private var estimatedCommission: Decimal = 0
    @State private var probability: Double = 0.5
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Client.lastName, ascending: true),
            NSSortDescriptor(keyPath: \Client.firstName, ascending: true)
        ]
    ) private var clients: FetchedResults<Client>
    
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
        task.estimatedCommission = estimatedCommission
        task.probability = probability
        task.createdAt = Date()
        task.updatedAt = Date()
        task.client = selectedClient
        task.stage = selectedStage
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}

class TasksViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    
    func loadTasks(context: NSManagedObjectContext, filter: TasksView.TaskFilter = .all) {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = filter.predicate
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Task.priority, ascending: false),
            NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)
        ]
        
        do {
            tasks = try context.fetch(request)
        } catch {
            print("Error loading tasks: \(error)")
        }
    }
}

#Preview {
    TasksView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager())
}

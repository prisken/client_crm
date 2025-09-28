import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var viewModel = DashboardViewModel()
    @State private var isSyncing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Welcome Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back!")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Here's your daily overview")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Firebase Sync Controls
                    VStack(spacing: 12) {
                        HStack {
                            Text("Firebase Sync")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Spacer()
                            if isSyncing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button("Sync All Data to Firebase") {
                                syncAllData()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isSyncing)
                            
                            Button("Fetch Data from Firebase") {
                                fetchAllData()
                            }
                            .buttonStyle(.bordered)
                            .disabled(isSyncing)
                        }
                        
                        if let syncError = firebaseManager.syncError {
                            Text("Sync Error: \(syncError)")
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        if let lastSync = firebaseManager.lastSyncDate {
                            Text("Last synced: \(lastSync, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Total Clients",
                            value: "\(viewModel.totalClients)",
                            icon: "person.2.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Active Tasks",
                            value: "\(viewModel.activeTasks)",
                            icon: "checklist",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "This Month's Commission",
                            value: viewModel.monthlyCommission,
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Target Progress",
                            value: viewModel.targetProgress,
                            icon: "target",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Today's Priority Tasks
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Today's Priority Tasks")
                                .font(.headline)
                            Spacer()
                            NavigationLink("View All", destination: TasksView())
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        
                        if viewModel.todayTasks.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.green)
                                Text("All caught up!")
                                    .font(.headline)
                                Text("No priority tasks for today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            ForEach(viewModel.todayTasks.prefix(3)) { task in
                                DashboardTaskRowView(task: task)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if viewModel.recentActivity.isEmpty {
                            Text("No recent activity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(viewModel.recentActivity.prefix(5)) { activity in
                                ActivityRowView(activity: activity)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Logout") {
                        authManager.logout()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadData(context: viewContext)
        }
    }
    
    // MARK: - Firebase Sync Functions
    private func syncAllData() {
        isSyncing = true
        
        // Fetch all clients and sync them
        let clientRequest: NSFetchRequest<Client> = Client.fetchRequest()
        do {
            let clients = try viewContext.fetch(clientRequest)
            for client in clients {
                firebaseManager.syncClient(client)
            }
            
            // Fetch all assets and sync them
            let assetRequest: NSFetchRequest<Asset> = Asset.fetchRequest()
            let assets = try viewContext.fetch(assetRequest)
            for asset in assets {
                firebaseManager.syncAsset(asset)
            }
            
            // Fetch all expenses and sync them
            let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
            let expenses = try viewContext.fetch(expenseRequest)
            for expense in expenses {
                firebaseManager.syncExpense(expense)
            }
            
            // Fetch all products and sync them
            let productRequest: NSFetchRequest<ClientProduct> = ClientProduct.fetchRequest()
            let products = try viewContext.fetch(productRequest)
            for product in products {
                firebaseManager.syncProduct(product)
            }
            
            print("✅ All data synced to Firebase")
        } catch {
            print("❌ Error syncing data: \(error)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSyncing = false
        }
    }
    
    private func fetchAllData() {
        isSyncing = true
        
        // Fetch all data from Firebase
        firebaseManager.fetchAllData(context: viewContext)
        
        // Refresh the dashboard data after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            viewModel.loadData(context: viewContext)
            isSyncing = false
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct DashboardTaskRowView: View {
    let task: Task
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .font(.headline)
                
                if let client = task.client {
                    Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                PriorityBadge(priority: Int(task.priority))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct PriorityBadge: View {
    let priority: Int
    
    var body: some View {
        Text(priorityText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var priorityText: String {
        switch priority {
        case 2: return "High"
        case 1: return "Medium"
        default: return "Low"
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case 2: return .red
        case 1: return .orange
        default: return .green
        }
    }
}

struct ActivityRowView: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack {
            Image(systemName: activity.icon)
                .foregroundColor(activity.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                Text(activity.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let title: String
    let timestamp: Date
    let icon: String
    let color: Color
}

class DashboardViewModel: ObservableObject {
    @Published var totalClients = 0
    @Published var activeTasks = 0
    @Published var monthlyCommission = "$0"
    @Published var targetProgress = "0%"
    @Published var todayTasks: [Task] = []
    @Published var recentActivity: [ActivityItem] = []
    
    func loadData(context: NSManagedObjectContext) {
        loadClientCount(context: context)
        loadTaskCount(context: context)
        loadCommissionData(context: context)
        loadTodayTasks(context: context)
        loadRecentActivity(context: context)
    }
    
    private func loadClientCount(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        do {
            totalClients = try context.count(for: request)
        } catch {
            print("Error loading client count: \(error)")
        }
    }
    
    private func loadTaskCount(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "pending")
        do {
            activeTasks = try context.count(for: request)
        } catch {
            print("Error loading task count: \(error)")
        }
    }
    
    private func loadCommissionData(context: NSManagedObjectContext) {
        // This would calculate actual commission data
        // For now, showing placeholder values
        monthlyCommission = "$2,450"
        targetProgress = "65%"
    }
    
    private func loadTodayTasks(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "pending")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.priority, ascending: false)]
        request.fetchLimit = 5
        
        do {
            todayTasks = try context.fetch(request)
        } catch {
            print("Error loading today's tasks: \(error)")
        }
    }
    
    private func loadRecentActivity(context: NSManagedObjectContext) {
        // This would load actual recent activity
        // For now, showing sample data
        recentActivity = [
            ActivityItem(
                title: "New client added: John Smith",
                timestamp: Date().addingTimeInterval(-3600),
                icon: "person.badge.plus",
                color: .blue
            ),
            ActivityItem(
                title: "Task completed: Follow up call",
                timestamp: Date().addingTimeInterval(-7200),
                icon: "checkmark.circle",
                color: .green
            ),
            ActivityItem(
                title: "WhatsApp message sent",
                timestamp: Date().addingTimeInterval(-10800),
                icon: "message",
                color: .green
            )
        ]
    }
    
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AuthenticationManager())
}



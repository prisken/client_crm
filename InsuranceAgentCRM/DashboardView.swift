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
                if DeviceInfo.isIPhone {
                    // iPhone Layout
                    LazyVStack(spacing: DeviceInfo.mobileSpacing) {
                        iPhoneWelcomeSection()
                        iPhoneSyncControls()
                        iPhoneStatsCards()
                        iPhoneRecentTasks()
                    }
                } else {
                    // iPad Layout - Single column like iPhone for simplicity
                    LazyVStack(spacing: DeviceInfo.mobileSpacing) {
                        iPhoneWelcomeSection()
                        iPhoneSyncControls()
                        iPhoneStatsCards()
                        iPhoneRecentTasks()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
                .onAppear {
                    // Fetch from Firebase first, then load local data
                    firebaseManager.fetchAllData(context: viewContext)
                    viewModel.loadData(context: viewContext, authManager: authManager)
                }
    }
    
    // MARK: - iPhone Components
    @ViewBuilder
    private func iPhoneWelcomeSection() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome Back!")
                .mobileTitle()
            
                        Text("Here's your daily overview")
                .mobileCaption()
            
            // User Email Display
            if let userEmail = authManager.currentUser?.email {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16))
                    Text("Logged in as: \(userEmail)")
                        .mobileCaption()
                        .lineLimit(1)
                }
                .padding(.top, 2)
            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
        .mobilePadding()
    }
    
    @ViewBuilder
    private func iPhoneSyncControls() -> some View {
        VStack(spacing: DeviceInfo.mobileSpacing) {
            HStack {
                Text("Firebase Sync")
                    .mobileSubtitle()
                Spacer()
                if isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            VStack(spacing: DeviceInfo.mobileSpacing) {
                Button("Sync All Data to Firebase") {
                    syncAllData()
                }
                .mobileButtonStyle(.primary)
                .disabled(isSyncing)
                
                Button("Fetch Data from Firebase") {
                    fetchAllData()
                }
                .mobileButtonStyle(.secondary)
                .disabled(isSyncing)
            }
            
            if let syncError = firebaseManager.syncError {
                Text("Sync Error: \(syncError)")
                    .mobileCaption()
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            if let lastSync = firebaseManager.lastSyncDate {
                Text("Last synced: \(lastSync, formatter: dateFormatter)")
                    .mobileCaption()
            }
        }
        .mobileCardStyle()
        .mobilePadding()
    }
    
    @ViewBuilder
    private func iPhoneStatsCards() -> some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: DeviceInfo.mobileSpacing) {
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
                title: "Commission",
                            value: viewModel.monthlyCommission,
                            icon: "dollarsign.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                title: "Progress",
                            value: viewModel.targetProgress,
                icon: "chart.bar.fill",
                            color: .purple
            )
        }
        .mobilePadding()
    }
    
    @ViewBuilder
    private func iPhoneRecentTasks() -> some View {
        VStack(alignment: .leading, spacing: DeviceInfo.mobileSpacing) {
            Text("Recent Tasks")
                .mobileSubtitle()
            
            if viewModel.recentTasks.isEmpty {
                Text("No recent tasks")
                    .mobileCaption()
                    .foregroundColor(.secondary)
            } else {
                ForEach(viewModel.recentTasks.prefix(3)) { task in
                    DashboardTaskRowView(task: task)
                }
            }
        }
        .mobileCardStyle()
        .mobilePadding()
    }
    
    // MARK: - iPad Dashboard Layout
    @ViewBuilder
    private func iPadDashboardLayout() -> some View {
        HStack(spacing: 0) {
            // Left Sidebar - Welcome & Quick Actions
            VStack(spacing: 0) {
                iPadWelcomeSection()
                Spacer()
            }
            .frame(width: 320)
            .background(Color(.systemGray6))
            
            // Main Content Area - Full utilization
            VStack(spacing: 0) {
                // Top Row - Stats Grid
                iPadStatsGrid()
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    .padding(.bottom, 16)
                
                // Middle Row - Charts and Analytics
                iPadAnalyticsSection()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                
                // Bottom Row - Recent Activity and Sync Controls
                iPadBottomSection()
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
        }
        .ignoresSafeArea(.all, edges: .bottom)
    }
    
    // MARK: - iPad Components
    @ViewBuilder
    private func iPadWelcomeSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Dashboard")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Welcome Back!")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // User Info Card
            if let userEmail = authManager.currentUser?.email {
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.blue.gradient)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Logged in as")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text(userEmail)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            }
            
            // Quick Actions
            VStack(alignment: .leading, spacing: 16) {
                Text("Quick Actions")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                
                VStack(spacing: 12) {
                    QuickActionButton(
                        title: "Add Client",
                        icon: "person.badge.plus",
                        color: .blue
                    ) {
                        // Add client action
                    }
                    
                    QuickActionButton(
                        title: "Create Task",
                        icon: "checklist",
                        color: .orange
                    ) {
                        // Create task action
                    }
                    
                    QuickActionButton(
                        title: "Sync Data",
                        icon: "arrow.clockwise.circle",
                        color: .green
                    ) {
                        syncAllData()
                    }
                    .disabled(isSyncing)
                }
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func iPadStatsGrid() -> some View {
        VStack(spacing: 16) {
            Text("Business Overview")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                EnhancedStatCard(
                    title: "Total Clients",
                    value: "\(viewModel.totalClients)",
                    subtitle: "Active clients",
                    icon: "person.2.fill",
                    color: .blue,
                    trend: "+12%"
                )
                
                EnhancedStatCard(
                    title: "Active Tasks",
                    value: "\(viewModel.activeTasks)",
                    subtitle: "Pending tasks",
                    icon: "checklist",
                    color: .orange,
                    trend: "+5%"
                )
                
                EnhancedStatCard(
                    title: "Monthly Commission",
                    value: viewModel.monthlyCommission,
                    subtitle: "This month",
                    icon: "dollarsign.circle.fill",
                    color: .green,
                    trend: "+8%"
                )
                
                EnhancedStatCard(
                    title: "Target Progress",
                    value: viewModel.targetProgress,
                    subtitle: "Annual goal",
                    icon: "chart.bar.fill",
                    color: .purple,
                    trend: "+15%"
                )
            }
        }
    }
    
    @ViewBuilder
    private func iPadAnalyticsSection() -> some View {
        HStack(spacing: 20) {
            // Performance Chart
            VStack(alignment: .leading, spacing: 16) {
                Text("Performance Trends")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Monthly Revenue")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("$12,450")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Growth")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            Text("+15%")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    
                    // Simple progress bar representation
                    VStack(spacing: 8) {
                        HStack {
                            Text("Q1 Target")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("75%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        
                        ProgressView(value: 0.75)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // Recent Activity Summary
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    ActivitySummaryRow(
                        icon: "person.badge.plus",
                        title: "New Clients",
                        value: "3",
                        color: .blue
                    )
                    
                    ActivitySummaryRow(
                        icon: "checklist",
                        title: "Tasks Completed",
                        value: "12",
                        color: .green
                    )
                    
                    ActivitySummaryRow(
                        icon: "dollarsign.circle",
                        title: "Commission Earned",
                        value: "$2,340",
                        color: .orange
                    )
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    @ViewBuilder
    private func iPadBottomSection() -> some View {
        HStack(spacing: 20) {
            // Recent Tasks
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Tasks")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    if viewModel.recentTasks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checklist")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No recent tasks")
                                .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        } else {
                        ForEach(viewModel.recentTasks.prefix(3)) { task in
                            EnhancedTaskRowView(task: task)
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // Sync Controls
            VStack(alignment: .leading, spacing: 16) {
                Text("Data Management")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                    HStack {
                        Text("Firebase Sync")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(1.2)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Button("Sync to Cloud") {
                            syncAllData()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSyncing)
                        .frame(maxWidth: .infinity)
                        
                        Button("Fetch from Cloud") {
                            fetchAllData()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSyncing)
                        .frame(maxWidth: .infinity)
                    }
                    
                    if let syncError = firebaseManager.syncError {
                        Text("Sync Error: \(syncError)")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let lastSync = firebaseManager.lastSyncDate {
                        Text("Last synced: \(lastSync, formatter: dateFormatter)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    @ViewBuilder
    private func iPadSyncAndTasksSection() -> some View {
        HStack(spacing: 24) {
            // Sync Controls
            VStack(alignment: .leading, spacing: 20) {
                Text("Data Management")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                VStack(spacing: 16) {
                        HStack {
                        Text("Firebase Sync")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                            Spacer()
                        
                        if isSyncing {
                            ProgressView()
                                .scaleEffect(1.2)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button("Sync to Cloud") {
                            syncAllData()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSyncing)
                        
                        Button("Fetch from Cloud") {
                            fetchAllData()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isSyncing)
                    }
                    
                    if let syncError = firebaseManager.syncError {
                        Text("Sync Error: \(syncError)")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let lastSync = firebaseManager.lastSyncDate {
                        Text("Last synced: \(lastSync, formatter: dateFormatter)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            
            // Recent Tasks
            VStack(alignment: .leading, spacing: 20) {
                        Text("Recent Activity")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    if viewModel.recentTasks.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "checklist")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No recent tasks")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        } else {
                        ForEach(viewModel.recentTasks.prefix(4)) { task in
                            EnhancedTaskRowView(task: task)
                        }
                    }
                }
                .padding(20)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    // MARK: - Helper Functions
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
            
            // Fetch all standalone products and sync them
            let standaloneProductRequest: NSFetchRequest<Product> = Product.fetchRequest()
            let standaloneProducts = try viewContext.fetch(standaloneProductRequest)
            for product in standaloneProducts {
                firebaseManager.syncStandaloneProduct(product)
            }
            
            // Fetch all tasks and sync them
            let taskRequest: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
            let tasks = try viewContext.fetch(taskRequest)
            for task in tasks {
                firebaseManager.syncTask(task)
            }
            
            // Fetch all tags and sync them
            let tagRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
            let tags = try viewContext.fetch(tagRequest)
            for tag in tags {
                firebaseManager.syncTag(tag)
            }
            
            // Fetch all relationships and sync them
            let relationshipRequest: NSFetchRequest<ClientRelationship> = ClientRelationship.fetchRequest()
            let relationships = try viewContext.fetch(relationshipRequest)
            for relationship in relationships {
                firebaseManager.syncRelationship(relationship)
            }
            
        } catch {
            print("Error syncing data: \(error)")
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
            viewModel.loadData(context: viewContext, authManager: authManager)
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

// MARK: - Supporting Components
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DeviceInfo.isIPhone ? 12 : 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: DeviceInfo.isIPhone ? 24 : 20))
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.system(size: DeviceInfo.isIPhone ? 28 : 22, weight: .bold))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: DeviceInfo.isIPhone ? 14 : 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .mobileCardStyle()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                Text(trend)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DashboardTaskRowView: View {
    let task: ClientTask
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled Task")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                
                if let client = task.client {
                    Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EnhancedTaskRowView: View {
    let task: ClientTask
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator
            Circle()
                .fill(task.isCompleted ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(task.title ?? "Untitled Task")
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                
                if let client = task.client {
                    Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(task.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                if !task.isCompleted {
                    Text("Pending")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Text("Completed")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(6)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct PriorityBadge: View {
    let priority: Int
    
    var body: some View {
        let (text, color) = priorityTextAndColor(for: priority)
        
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
    
    private func priorityTextAndColor(for priority: Int) -> (String, Color) {
        switch priority {
        case 1:
            return ("High", .red)
        case 2:
            return ("Medium", .orange)
        case 3:
            return ("Low", .green)
        default:
            return ("Normal", .blue)
        }
    }
}

// MARK: - Dashboard ViewModel
class DashboardViewModel: ObservableObject {
    @Published var totalClients = 0
    @Published var activeTasks = 0
    @Published var monthlyCommission = "$0"
    @Published var targetProgress = "0%"
    @Published var recentTasks: [ClientTask] = []
    
    func loadData(context: NSManagedObjectContext, authManager: AuthenticationManager) {
        loadClientCount(context: context, authManager: authManager)
        loadTaskCount(context: context)
        loadCommissionData(context: context)
        loadRecentTasks(context: context)
    }
    
    private func loadClientCount(context: NSManagedObjectContext, authManager: AuthenticationManager) {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        
        // Filter by current user only
        if let currentUser = authManager.currentUser {
            request.predicate = NSPredicate(format: "owner == %@", currentUser)
        }
        
        do {
            totalClients = try context.count(for: request)
        } catch {
            totalClients = 0
        }
    }
    
    private func loadTaskCount(context: NSManagedObjectContext) {
        let request: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        do {
            activeTasks = try context.count(for: request)
        } catch {
            activeTasks = 0
        }
    }
    
    private func loadCommissionData(context: NSManagedObjectContext) {
        // This would calculate actual commission data
        // For now, showing placeholder values
        monthlyCommission = "$2,450"
        targetProgress = "65%"
    }
    
    private func loadRecentTasks(context: NSManagedObjectContext) {
        let request: NSFetchRequest<ClientTask> = ClientTask.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClientTask.createdAt, ascending: false)]
        request.fetchLimit = 5
        
        do {
            recentTasks = try context.fetch(request)
        } catch {
            recentTasks = []
        }
    }
}

struct ActivitySummaryRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}



import Foundation
import CoreData

struct OptimizedTask {
    let task: Task
    let value: Double          // c' + α * priority
    let effortUnits: Int       // h' (tenths of hour)
}

struct OptimizerResult {
    let tasks: [Task]          // final ordered list
    let overloadDetected: Bool // true when mandatory > capacity
    let totalExpectedCommission: Double
    let totalEffortHours: Double
}

class CommissionOptimizerService {
    
    // MARK: - Constants
    private let hourGranularity = 10               // 0.1-hour units
    private let alpha = 0.1                        // priority weight
    private let defaultDailyHours = 8.0
    
    // MARK: - Main Optimization Function
    func buildTaskList(
        for date: Date,
        allOpenTasks: [Task],
        dailyHours: Double = 8.0,
        monthlyTarget: Decimal,
        earnedSoFar: Decimal
    ) -> OptimizerResult {
        
        // Calculate beta scaling factor based on target gap
        let gap = NSDecimalNumber(decimal: monthlyTarget - earnedSoFar)
        let targetAmount = NSDecimalNumber(decimal: monthlyTarget)
        let betaRaw = 1.0 + max(gap.doubleValue / targetAmount.doubleValue, 0.0)
        let betaClamped = min(max(betaRaw, 1.0), 2.0)
        
        // Split mandatory vs optional tasks
        var mandatory: [OptimizedTask] = []
        var optional: [OptimizedTask] = []
        
        for task in allOpenTasks {
            let optimizedTask = createOptimizedTask(
                task: task,
                betaClamped: betaClamped,
                date: date
            )
            
            // Check if task is due today or overdue
            if Calendar.current.isDate(task.dueDate ?? Date(), inSameDayAs: date) ||
               (task.dueDate ?? Date()) < date {
                mandatory.append(optimizedTask)
            } else {
                optional.append(optimizedTask)
            }
        }
        
        // Verify time budget for mandatory tasks
        let mandatoryUnits = mandatory.reduce(0) { $0 + $1.effortUnits }
        let totalUnits = Int(dailyHours * Double(hourGranularity))
        
        guard mandatoryUnits <= totalUnits else {
            // Overload detected - return only mandatory tasks
            return OptimizerResult(
                tasks: mandatory.map { $0.task },
                overloadDetected: true,
                totalExpectedCommission: mandatory.reduce(0) { $0 + $1.value },
                totalEffortHours: Double(mandatoryUnits) / Double(hourGranularity)
            )
        }
        
        // Run DP knapsack on optional tasks
        let selectedOptional = runKnapsack(
            items: optional,
            capacity: totalUnits - mandatoryUnits
        )
        
        // Combine and sort final tasks
        var finalTasks = mandatory + selectedOptional
        finalTasks.sort { task1, task2 in
            // Overdue tasks first
            let task1Overdue = (task1.task.dueDate ?? Date()) <= date
            let task2Overdue = (task2.task.dueDate ?? Date()) <= date
            
            if task1Overdue && !task2Overdue { return true }
            if !task1Overdue && task2Overdue { return false }
            
            // Then by value, then by priority
            if task1.value != task2.value { return task1.value > task2.value }
            return task1.task.priority > task2.task.priority
        }
        
        let totalCommission = finalTasks.reduce(0) { $0 + $1.value }
        let totalEffort = Double(finalTasks.reduce(0) { $0 + $1.effortUnits }) / Double(hourGranularity)
        
        return OptimizerResult(
            tasks: finalTasks.map { $0.task },
            overloadDetected: false,
            totalExpectedCommission: totalCommission,
            totalEffortHours: totalEffort
        )
    }
    
    // MARK: - Helper Functions
    private func createOptimizedTask(
        task: Task,
        betaClamped: Double,
        date: Date
    ) -> OptimizedTask {
        // Convert effort hours to integer units
        let effortUnits = Int((task.effortHours * Double(hourGranularity)).rounded())
        
        // Calculate base expected commission
        let baseCommission = task.estimatedCommission?.doubleValue ?? 0.0
        let scaledCommission = baseCommission * betaClamped
        
        // Add priority weight
        let value = scaledCommission + alpha * Double(task.priority)
        
        return OptimizedTask(
            task: task,
            value: value,
            effortUnits: effortUnits
        )
    }
    
    private func runKnapsack(
        items: [OptimizedTask],
        capacity: Int
    ) -> [OptimizedTask] {
        guard !items.isEmpty && capacity > 0 else { return [] }
        
        let n = items.count
        var dp = Array(repeating: Array(repeating: 0.0, count: capacity + 1), count: n + 1)
        
        // Fill DP table
        for i in 1...n {
            let item = items[i - 1]
            for w in 0...capacity {
                if item.effortUnits <= w {
                    let take = dp[i - 1][w - item.effortUnits] + item.value
                    let skip = dp[i - 1][w]
                    dp[i][w] = max(take, skip)
                } else {
                    dp[i][w] = dp[i - 1][w]
                }
            }
        }
        
        // Backtrack to find selected items
        var selectedItems: [OptimizedTask] = []
        var w = capacity
        var i = n
        
        while i > 0 {
            if dp[i][w] != dp[i - 1][w] {
                let chosen = items[i - 1]
                selectedItems.append(chosen)
                w -= chosen.effortUnits
            }
            i -= 1
        }
        
        return selectedItems
    }
    
    // MARK: - What-If Analysis
    func whatIfAnalysis(
        baseTasks: [Task],
        modifiedTask: Task,
        date: Date,
        dailyHours: Double = 8.0,
        monthlyTarget: Decimal,
        earnedSoFar: Decimal
    ) -> OptimizerResult {
        var modifiedTasks = baseTasks
        if let index = modifiedTasks.firstIndex(where: { $0.id == modifiedTask.id }) {
            modifiedTasks[index] = modifiedTask
        } else {
            modifiedTasks.append(modifiedTask)
        }
        
        return buildTaskList(
            for: date,
            allOpenTasks: modifiedTasks,
            dailyHours: dailyHours,
            monthlyTarget: monthlyTarget,
            earnedSoFar: earnedSoFar
        )
    }
    
    // MARK: - Performance Metrics
    func calculatePerformanceMetrics(
        tasks: [Task],
        date: Date
    ) -> (averageValuePerHour: Double, totalExpectedCommission: Double, efficiency: Double) {
        let totalCommission = tasks.reduce(0.0) { total, task in
            total + (task.estimatedCommission?.doubleValue ?? 0.0) * task.probability
        }
        
        let totalHours = tasks.reduce(0.0) { $0 + $1.effortHours }
        let averageValuePerHour = totalHours > 0 ? totalCommission / totalHours : 0.0
        
        // Calculate efficiency as ratio of high-priority tasks
        let highPriorityTasks = tasks.filter { $0.priority >= 2 }
        let efficiency = tasks.isEmpty ? 0.0 : Double(highPriorityTasks.count) / Double(tasks.count)
        
        return (
            averageValuePerHour: averageValuePerHour,
            totalExpectedCommission: totalCommission,
            efficiency: efficiency
        )
    }
}

// MARK: - Today's Tasks View Model
class TodayTasksViewModel: ObservableObject {
    @Published var todayQueue: [Task] = []
    @Published var isOverloaded = false
    @Published var totalExpectedCommission: Double = 0.0
    @Published var totalEffortHours: Double = 0.0
    @Published var performanceMetrics: (averageValuePerHour: Double, totalExpectedCommission: Double, efficiency: Double) = (0.0, 0.0, 0.0)
    
    private let optimizer = CommissionOptimizerService()
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func loadTodayQueue() {
        let openTasks = fetchOpenTasks()
        let target = fetchMonthlyTarget()
        let earned = fetchEarnedCommission()
        
        let result = optimizer.buildTaskList(
            for: Date(),
            allOpenTasks: openTasks,
            dailyHours: 8.0,
            monthlyTarget: target,
            earnedSoFar: earned
        )
        
        DispatchQueue.main.async {
            self.isOverloaded = result.overloadDetected
            self.todayQueue = result.tasks
            self.totalExpectedCommission = result.totalExpectedCommission
            self.totalEffortHours = result.totalEffortHours
            self.performanceMetrics = self.optimizer.calculatePerformanceMetrics(
                tasks: result.tasks,
                date: Date()
            )
        }
    }
    
    func refreshRecommendations() {
        loadTodayQueue()
    }
    
    func whatIfAnalysis(for task: Task, with newProbability: Double, newEffortHours: Double) -> OptimizerResult {
        let modifiedTask = task
        modifiedTask.probability = newProbability
        modifiedTask.effortHours = newEffortHours
        
        let openTasks = fetchOpenTasks()
        let target = fetchMonthlyTarget()
        let earned = fetchEarnedCommission()
        
        return optimizer.whatIfAnalysis(
            baseTasks: openTasks,
            modifiedTask: modifiedTask,
            date: Date(),
            dailyHours: 8.0,
            monthlyTarget: target,
            earnedSoFar: earned
        )
    }
    
    // MARK: - Data Fetching
    private func fetchOpenTasks() -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "status == %@", "pending")
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching open tasks: \(error)")
            return []
        }
    }
    
    private func fetchMonthlyTarget() -> Decimal {
        let calendar = Calendar.current
        let now = Date()
        let month = Int16(calendar.component(.month, from: now))
        let year = Int16(calendar.component(.year, from: now))
        
        let request: NSFetchRequest<CommissionTarget> = CommissionTarget.fetchRequest()
        request.predicate = NSPredicate(format: "month == %d AND year == %d", month, year)
        request.fetchLimit = 1
        
        do {
            let targets = try context.fetch(request)
            return (targets.first?.targetAmount as? Decimal) ?? 0
        } catch {
            print("Error fetching monthly target: \(error)")
            return 0
        }
    }
    
    private func fetchEarnedCommission() -> Decimal {
        // This would calculate actual earned commission from completed deals
        // For now, returning a placeholder
        return 0
    }
}



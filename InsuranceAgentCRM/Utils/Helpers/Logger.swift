import Foundation
import os.log

// MARK: - Log Level
enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
    
    var emoji: String {
        switch self {
        case .debug:
            return "🔍"
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .critical:
            return "🚨"
        }
    }
}

// MARK: - Logger
class Logger {
    static let shared = Logger()
    
    private let osLog = OSLog(subsystem: AppConstants.App.bundleIdentifier, category: "General")
    private let isDebugMode = AppEnvironment.isDebug
    
    private init() {}
    
    // MARK: - Public Logging Methods
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message: message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message: message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message: message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message: message, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message: message, file: file, function: function, line: line)
    }
    
    // MARK: - Private Logging Implementation
    private func log(_ level: LogLevel, message: String, file: String, function: String, line: Int) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        
        let logMessage = "\(level.emoji) [\(level.rawValue)] \(timestamp) \(fileName):\(line) \(function) - \(message)"
        
        // Always log to console in debug mode
        if isDebugMode {
            print(logMessage)
        }
        
        // Log to OSLog for production
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
    }
}

// MARK: - Convenience Functions
func logDebug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.debug(message, file: file, function: function, line: line)
}

func logInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.info(message, file: file, function: function, line: line)
}

func logWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.warning(message, file: file, function: function, line: line)
}

func logError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.error(message, file: file, function: function, line: line)
}

func logCritical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    Logger.shared.critical(message, file: file, function: function, line: line)
}

// MARK: - Specialized Loggers
extension Logger {
    // MARK: - Authentication Logger
    func auth(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let authLog = OSLog(subsystem: AppConstants.App.bundleIdentifier, category: "Authentication")
        let logMessage = "🔐 AUTH - \(message)"
        os_log("%{public}@", log: authLog, type: .info, logMessage)
        
        if isDebugMode {
            print(logMessage)
        }
    }
    
    // MARK: - Network Logger
    func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let networkLog = OSLog(subsystem: AppConstants.App.bundleIdentifier, category: "Network")
        let logMessage = "🌐 NETWORK - \(message)"
        os_log("%{public}@", log: networkLog, type: .info, logMessage)
        
        if isDebugMode {
            print(logMessage)
        }
    }
    
    // MARK: - Database Logger
    func database(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let dbLog = OSLog(subsystem: AppConstants.App.bundleIdentifier, category: "Database")
        let logMessage = "💾 DATABASE - \(message)"
        os_log("%{public}@", log: dbLog, type: .info, logMessage)
        
        if isDebugMode {
            print(logMessage)
        }
    }
    
    // MARK: - UI Logger
    func ui(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let uiLog = OSLog(subsystem: AppConstants.App.bundleIdentifier, category: "UI")
        let logMessage = "🎨 UI - \(message)"
        os_log("%{public}@", log: uiLog, type: .info, logMessage)
        
        if isDebugMode {
            print(logMessage)
        }
    }
}

// MARK: - Performance Logger
extension Logger {
    func performance(_ operation: String, duration: TimeInterval, file: String = #file, function: String = #function, line: Int = #line) {
        let perfLog = OSLog(subsystem: AppConstants.App.bundleIdentifier, category: "Performance")
        let logMessage = "⚡ PERFORMANCE - \(operation) took \(String(format: "%.3f", duration))s"
        os_log("%{public}@", log: perfLog, type: .info, logMessage)
        
        if isDebugMode {
            print(logMessage)
        }
    }
}

// MARK: - Performance Measurement Helper
func measurePerformance<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
    let startTime = CFAbsoluteTimeGetCurrent()
    let result = try block()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    Logger.shared.performance(operation, duration: timeElapsed)
    return result
}

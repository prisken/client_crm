import Foundation
import SwiftUI
import UIKit

struct AppConstants {
    // MARK: - App Information
    struct App {
        static let name = "Insurance Agent CRM"
        static let version = "1.0.0"
        static let bundleIdentifier = "com.insuranceagent.crm.InsuranceAgentCRM"
    }
    
    // MARK: - User Defaults Keys
    struct UserDefaultsKeys {
        static let isFirstLaunch = "isFirstLaunch"
        static let lastSyncDate = "lastSyncDate"
        static let userPreferences = "userPreferences"
        static let selectedTheme = "selectedTheme"
        static let notificationsEnabled = "notificationsEnabled"
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let short = 0.2
        static let medium = 0.3
        static let long = 0.5
        static let spring = 0.6
    }
    
    // MARK: - Layout Constants
    struct Layout {
        static let cornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 20
        static let itemSpacing: CGFloat = 8
        static let minimumTouchTarget: CGFloat = 44
    }
    
    // MARK: - API Constants
    struct API {
        static let baseURL = "https://api.insuranceagentcrm.com"
        static let timeout: TimeInterval = 30
        static let maxRetries = 3
    }
    
    // MARK: - Validation Constants
    struct Validation {
        static let minPasswordLength = 8
        static let maxPasswordLength = 50
        static let minNameLength = 2
        static let maxNameLength = 50
        static let maxEmailLength = 100
        static let maxPhoneLength = 20
        static let maxNotesLength = 1000
    }
    
    // MARK: - Date Formats
    struct DateFormat {
        static let short = "MMM d, yyyy"
        static let medium = "MMM d, yyyy 'at' h:mm a"
        static let long = "EEEE, MMMM d, yyyy 'at' h:mm a"
        static let timeOnly = "h:mm a"
        static let dateOnly = "MMM d, yyyy"
        static let iso8601 = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    }
    
    // MARK: - Notification Names
    struct Notifications {
        static let userDidLogin = Notification.Name("userDidLogin")
        static let userDidLogout = Notification.Name("userDidLogout")
        static let dataDidSync = Notification.Name("dataDidSync")
        static let taskDidComplete = Notification.Name("taskDidComplete")
        static let clientDidUpdate = Notification.Name("clientDidUpdate")
    }
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let networkError = "Network connection error. Please check your internet connection."
        static let serverError = "Server error. Please try again later."
        static let validationError = "Please check your input and try again."
        static let authenticationError = "Authentication failed. Please log in again."
        static let unknownError = "An unexpected error occurred. Please try again."
    }
    
    // MARK: - Success Messages
    struct SuccessMessages {
        static let loginSuccess = "Successfully logged in"
        static let logoutSuccess = "Successfully logged out"
        static let saveSuccess = "Changes saved successfully"
        static let deleteSuccess = "Item deleted successfully"
        static let syncSuccess = "Data synchronized successfully"
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let enableWhatsAppIntegration = true
        static let enablePushNotifications = true
        static let enableAnalytics = true
        static let enableCrashReporting = true
        static let enableDarkMode = true
    }
    
    // MARK: - Limits
    struct Limits {
        static let maxClientsPerUser = 1000
        static let maxTasksPerClient = 100
        static let maxFileSize = 10 * 1024 * 1024 // 10MB
        static let maxImageSize = 5 * 1024 * 1024 // 5MB
        static let maxSearchResults = 100
    }
}

// MARK: - Environment Keys
struct AppEnvironment {
    static let isDebug = _isDebugAssertConfiguration()
    static let isSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    static let isProduction = !isDebug && !isSimulator
}

// MARK: - Device Information
struct DeviceInfo {
    static let isIPad = UIDevice.current.userInterfaceIdiom == .pad
    static let isIPhone = UIDevice.current.userInterfaceIdiom == .phone
    static let screenWidth = UIScreen.main.bounds.width
    static let screenHeight = UIScreen.main.bounds.height
    static let isSmallScreen = screenWidth < 375
    static let isLargeScreen = screenWidth > 414
    static let isCompactWidth = screenWidth < 768 // iPad Pro 11" and below, all iPhones
    static let isRegularWidth = !isCompactWidth // iPad Pro 12.9" and larger
}

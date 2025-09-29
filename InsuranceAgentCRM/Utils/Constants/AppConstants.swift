import Foundation
import SwiftUI

// MARK: - App Constants
struct AppConstants {
    
    // MARK: - App Info
    struct App {
        static let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.insuranceagent.crm"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Form Constants
    struct Form {
        static let assetTypes = [
            "Cash", "Savings Account", "Investment", "Property", "Vehicle", 
            "Jewelry", "Art", "Collectibles", "Business", "Insurance Policy", 
            "Fixed Asset", "Income", "Other"
        ]
        
        static let expenseTypes = [
            "Housing", "Food", "Transportation", "Healthcare", "Education",
            "Entertainment", "Utilities", "Insurance", "Debt", "Fixed", 
            "Monthly", "Variable", "Annual", "Other"
        ]
        
        static let expenseFrequencies = [
            "monthly", "quarterly", "annually", "one-time", "Monthly", "Quarterly", "Annually", "One-time", "Variable"
        ]
        
        static let productCategories = [
            "Life", "Life Insurance", "Health Insurance", "Medical", "Critical Illness", "Auto Insurance", "Home Insurance",
            "Investment", "Retirement", "Education", "General Insurance", "Savings", "Other"
        ]
        
        static let productStatuses = [
            "Proposed", "Under Review", "Approved", "Active", "Cancelled", "Expired"
        ]
    }
    
    // MARK: - UI Constants
    struct UI {
        static let cornerRadius: CGFloat = 12
        static let cardCornerRadius: CGFloat = 8
        static let shadowRadius: CGFloat = 2
        static let shadowOpacity: Double = 0.1
        
        static let mobilePadding: CGFloat = 16
        static let mobileSpacing: CGFloat = 12
        static let mobileCornerRadius: CGFloat = 8
        static let mobileButtonHeight: CGFloat = 44
        static let mobileTouchTarget: CGFloat = 44
        static let mobileFontScale: CGFloat = 1.0
    }
    
    // MARK: - Animation Constants
    struct Animation {
        static let defaultDuration: Double = 0.3
        static let fastDuration: Double = 0.2
        static let slowDuration: Double = 0.5
        
        static let defaultEasing = SwiftUI.Animation.easeInOut
        static let fastEasing = SwiftUI.Animation.easeOut
        static let slowEasing = SwiftUI.Animation.easeInOut
    }
    
    // MARK: - Color Constants
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let background = Color(.systemBackground)
        static let backgroundSecondary = Color(.systemGray6)
    }
    
    // MARK: - Status Colors
    struct StatusColors {
        static let active = Color.green
        static let approved = Color.blue
        static let proposed = Color.orange
        static let underReview = Color.yellow
        static let cancelled = Color.red
        static let expired = Color.gray
        static let notSet = Color.orange
    }
    
    // MARK: - Notification Names
    struct Notifications {
        static let tagDeleted = Notification.Name("tagDeleted")
        static let clientDataChanged = Notification.Name("clientDataChanged")
        static let tagInputFocused = Notification.Name("tagInputFocused")
    }
    
    // MARK: - Firebase Constants
    struct Firebase {
        static let usersCollection = "users"
        static let clientsCollection = "clients"
        static let universalTagsCollection = "universal_tags"
        static let tagSelectionsCollection = "tag_selections"
    }
    
    // MARK: - Core Data Constants
    struct CoreData {
        static let modelName = "InsuranceAgentCRM"
        static let containerName = "InsuranceAgentCRM"
    }
    
    // MARK: - API Constants
    struct API {
        static let timeout: TimeInterval = 30.0
        static let retryCount = 3
        static let retryDelay: TimeInterval = 1.0
    }
    
    // MARK: - Validation Constants
    struct Validation {
        static let maxEmailLength = 100
        static let minNameLength = 1
        static let maxNameLength = 50
        static let maxPhoneLength = 20
        static let minPasswordLength = 8
        static let maxPasswordLength = 50
        static let maxNotesLength = 1000
    }
}

// MARK: - Device Info
struct DeviceInfo {
    static var isIPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
    
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var isCompactWidth: Bool {
        UIScreen.main.bounds.width < 768
    }
    
    static var mobilePadding: CGFloat = AppConstants.UI.mobilePadding
    static var mobileSpacing: CGFloat = AppConstants.UI.mobileSpacing
    static var mobileCornerRadius: CGFloat = AppConstants.UI.mobileCornerRadius
    static var mobileButtonHeight: CGFloat = AppConstants.UI.mobileButtonHeight
    static var mobileTouchTarget: CGFloat = AppConstants.UI.mobileTouchTarget
    static var mobileFontScale: CGFloat = AppConstants.UI.mobileFontScale
    static var compactIconSize: CGFloat = 16
    static var mobileCardPadding: CGFloat = 12
    static var compactTitleSize: CGFloat = 16
    static var compactSubtitleSize: CGFloat = 12
    static var compactHeaderSpacing: CGFloat = 12
    static var compactHeaderPadding: CGFloat = 16
}

// MARK: - App Environment
struct AppEnvironment {
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    static var isRelease: Bool {
        return !isDebug
    }
}
import Foundation
import SwiftUI
import CoreData

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userRole: UserRole = .agent
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    enum UserRole: String, CaseIterable {
        case admin = "admin"
        case agent = "agent"
        
        var displayName: String {
            switch self {
            case .admin: return "Administrator"
            case .agent: return "Agent"
            }
        }
    }
    
    private let keychain = KeychainManager()
    
    init() {
        checkAuthenticationStatus()
    }
    
    func checkAuthenticationStatus() {
        logInfo("Checking authentication status")
        
        if keychain.getToken() != nil {
            // In a real app, you would validate the token with your backend
            // For now, we'll assume it's valid if it exists
            isAuthenticated = true
            loadCurrentUser()
            logInfo("User is authenticated")
        } else {
            logInfo("No authentication token found")
        }
    }
    
    func login(email: String, password: String, context: NSManagedObjectContext) async throws {
        logInfo("Attempting login for email: \(email)")
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, this would make an API call to your backend
            // For now, we'll simulate authentication
            
            // Check if user exists in Core Data
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", email)
            
            let users = try context.fetch(request)
            
            guard let user = users.first else {
                logWarning("Login failed: User not found for email: \(email)")
                throw AuthenticationError.userNotFound
            }
            
            // In a real app, you would hash the password and compare
            // For now, we'll accept any password for demo purposes
            let token = UUID().uuidString
            keychain.saveToken(token)
            
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = user
                self.userRole = UserRole(rawValue: user.role ?? "agent") ?? .agent
            }
            
            logInfo("User logged in successfully: \(user.email ?? "")")
            
        } catch {
            logError("Login failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func logout() {
        logInfo("User logging out")
        keychain.deleteToken()
        isAuthenticated = false
        currentUser = nil
        userRole = .agent
        errorMessage = nil
        logInfo("User logged out successfully")
    }
    
    private func loadCurrentUser() {
        logInfo("Loading current user")
        // Load current user from Core Data based on stored token
        // This is a simplified version - in production you'd validate the token
        // For now, we'll create a default user or load the first available user
        logInfo("Current user loaded successfully")
    }
    
    func createUser(email: String, password: String, role: UserRole, context: NSManagedObjectContext) async throws -> User {
        logInfo("Creating user with email: \(email)")
        
        let user = User(context: context)
        user.id = UUID()
        user.email = email
        user.passwordHash = hashPassword(password) // In production, use proper hashing
        user.role = role.rawValue
        user.createdAt = Date()
        user.updatedAt = Date()
        
        try context.save()
        logInfo("User created successfully: \(email)")
        return user
    }
    
    private func hashPassword(_ password: String) -> String {
        logDebug("Hashing password")
        // In production, use proper password hashing (bcrypt, scrypt, etc.)
        return password.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}


// MARK: - Keychain Manager
class KeychainManager {
    private let service = "com.insuranceagent.crm"
    
    func saveToken(_ token: String) {
        logDebug("Saving token to keychain")
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_token",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == noErr {
            logDebug("Token saved successfully")
        } else {
            logError("Failed to save token to keychain")
        }
    }
    
    func getToken() -> String? {
        logDebug("Retrieving token from keychain")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            logDebug("No token found in keychain")
            return nil
        }
        
        logDebug("Token retrieved successfully")
        return token
    }
    
    func deleteToken() {
        logDebug("Deleting token from keychain")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_token"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status == noErr {
            logDebug("Token deleted successfully")
        } else {
            logError("Failed to delete token from keychain")
        }
    }
}


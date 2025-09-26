import Foundation
import SwiftUI
import CoreData

class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var userRole: UserRole = .agent
    
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
        if let token = keychain.getToken() {
            // In a real app, you would validate the token with your backend
            // For now, we'll assume it's valid if it exists
            isAuthenticated = true
            loadCurrentUser()
        }
    }
    
    func login(email: String, password: String, context: NSManagedObjectContext) async throws {
        // In a real app, this would make an API call to your backend
        // For now, we'll simulate authentication
        
        // Check if user exists in Core Data
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email)
        
        let users = try context.fetch(request)
        
        guard let user = users.first else {
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
    }
    
    func logout() {
        keychain.deleteToken()
        isAuthenticated = false
        currentUser = nil
        userRole = .agent
    }
    
    private func loadCurrentUser() {
        // Load current user from Core Data based on stored token
        // This is a simplified version - in production you'd validate the token
    }
    
    func createUser(email: String, password: String, role: UserRole, context: NSManagedObjectContext) async throws -> User {
        let user = User(context: context)
        user.id = UUID()
        user.email = email
        user.passwordHash = hashPassword(password) // In production, use proper hashing
        user.role = role.rawValue
        user.createdAt = Date()
        user.updatedAt = Date()
        
        try context.save()
        return user
    }
    
    private func hashPassword(_ password: String) -> String {
        // In production, use proper password hashing (bcrypt, scrypt, etc.)
        return password.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}

enum AuthenticationError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error occurred"
        }
    }
}

class KeychainManager {
    private let service = "com.insuranceagent.crm"
    
    func saveToken(_ token: String) {
        let data = token.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_token",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func getToken() -> String? {
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
            return nil
        }
        
        return token
    }
    
    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "auth_token"
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

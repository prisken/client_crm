import Foundation
import SwiftUI
import CoreData
import FirebaseAuth

// Type aliases for clarity
typealias CoreDataUser = User
typealias FirebaseAuthUser = FirebaseAuth.User

// MARK: - Authentication Manager
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: CoreDataUser? // Core Data User
    @Published var firebaseUser: FirebaseAuthUser? // Firebase Auth User
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
        
        // Check Firebase Auth status first
        if let firebaseUser = Auth.auth().currentUser {
            self.firebaseUser = firebaseUser
            
            // Load or create local Core Data user
            loadOrCreateLocalUser(firebaseUser: firebaseUser)
            
            // Set authentication status
            isAuthenticated = true
            
            // Save Firebase token
            firebaseUser.getIDToken { [weak self] token, error in
                if let token = token {
                    self?.keychain.saveToken(token)
                }
            }
            
        } else {
            // Check local token as fallback
            if keychain.getToken() != nil {
                isAuthenticated = true
                loadCurrentUser()
            } else {
                isAuthenticated = false
            }
        }
    }
    
    func login(email: String, password: String, context: NSManagedObjectContext) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Try Firebase Authentication first
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            
            // Check if user exists in Core Data
            let request: NSFetchRequest<CoreDataUser> = User.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", email)
            
            let users = try context.fetch(request)
            
            var user: User
            if let existingUser = users.first {
                // User exists in Core Data, use it
                user = existingUser
            } else {
                // User doesn't exist in Core Data, create it
                user = CoreDataUser(context: context)
                user.id = UUID()
                user.email = email
                user.role = "agent" // Default role
                user.createdAt = Date()
                user.updatedAt = Date()
                user.passwordHash = "" // No need to store password with Firebase
                
                try context.save()
            }
            
            // Save Firebase token
            let idToken = try await authResult.user.getIDToken()
            keychain.saveToken(idToken)
            
            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = user
                self.userRole = UserRole(rawValue: user.role ?? "agent") ?? .agent
            }
            
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    func logout() {
        
        // Sign out from Firebase
        do {
            try Auth.auth().signOut()
        } catch {
        }
        
        keychain.deleteToken()
        isAuthenticated = false
        currentUser = nil
        userRole = .agent
        errorMessage = nil
    }
    
    
    private func loadCurrentUser() {
        // Load the first available user from Core Data
        // In production, you would validate the stored token and load the specific user
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<CoreDataUser> = CoreDataUser.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let users = try context.fetch(request)
            if let user = users.first {
                self.currentUser = user
                self.userRole = UserRole(rawValue: user.role ?? "agent") ?? .agent
            }
        } catch {
        }
    }
    
    private func loadOrCreateLocalUser(firebaseUser: FirebaseAuthUser) {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<CoreDataUser> = CoreDataUser.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", firebaseUser.email ?? "")
        
        do {
            let users = try context.fetch(request)
            if let existingUser = users.first {
                // User exists, update if needed
                self.currentUser = existingUser
                self.userRole = UserRole(rawValue: existingUser.role ?? "agent") ?? .agent
            } else {
                // Create new user in Core Data
                let newUser = CoreDataUser(context: context)
                newUser.id = UUID()
                newUser.email = firebaseUser.email
                newUser.role = UserRole.agent.rawValue // Default role
                newUser.createdAt = Date()
                newUser.updatedAt = Date()
                // No password hash needed for Firebase users
                
                try context.save()
                self.currentUser = newUser
                self.userRole = .agent
            }
        } catch {
        }
    }
    
    func createUser(email: String, password: String, role: UserRole, context: NSManagedObjectContext) async throws -> User {
        
        do {
            // Create Firebase user
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Create Core Data user
            let user = CoreDataUser(context: context)
            user.id = UUID()
            user.email = email
            user.passwordHash = "" // No need to store password hash with Firebase
            user.role = role.rawValue
            user.createdAt = Date()
            user.updatedAt = Date()
            
            try context.save()
            
            // Save Firebase token
            let idToken = try await authResult.user.getIDToken()
            keychain.saveToken(idToken)
            
            return user
            
        } catch {
            throw error
        }
    }
    
    private func hashPassword(_ password: String) -> String {
        // In production, use proper password hashing (bcrypt, scrypt, etc.)
        return password.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}


// MARK: - Keychain Manager
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
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == noErr {
        } else {
        }
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
        
        let status = SecItemDelete(query as CFDictionary)
        if status == noErr {
        } else {
        }
    }
}


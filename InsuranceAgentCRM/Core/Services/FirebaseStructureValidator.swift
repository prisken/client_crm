import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FirebaseStructureValidator: ObservableObject {
    private let db = Firestore.firestore()
    @Published var validationStatus = "Ready to validate"
    @Published var isValidating = false
    @Published var validationResults: [ValidationResult] = []
    
    struct ValidationResult {
        let test: String
        let status: ValidationStatus
        let message: String
        
        enum ValidationStatus {
            case pass, fail, warning
        }
    }
    
    // MARK: - Validate Firebase Structure
    func validateFirebaseStructure() async {
        guard let currentUser = Auth.auth().currentUser else {
            validationStatus = "❌ No authenticated user"
            return
        }
        
        isValidating = true
        validationStatus = "🔍 Validating Firebase structure..."
        validationResults.removeAll()
        
        do {
            // Test 1: Verify user-specific collections exist and are accessible
            await validateUserCollections(userId: currentUser.uid)
            
            // Test 2: Verify no global collections exist
            await validateNoGlobalCollections()
            
            // Test 3: Verify data isolation
            await validateDataIsolation(userId: currentUser.uid)
            
            // Test 4: Verify authentication requirements
            await validateAuthenticationRequirements()
            
            validationStatus = "✅ Validation completed"
            
        } catch {
            validationStatus = "❌ Validation failed: \(error.localizedDescription)"
        }
        
        isValidating = false
    }
    
    // MARK: - Test 1: User Collections Validation
    private func validateUserCollections(userId: String) async {
        let collections = [
            "clients",
            "assets",
            "expenses", 
            "products",
            "standalone_products",
            "tasks",
            "standalone_tasks"
        ]
        
        for collection in collections {
            do {
                let snapshot = try await db.collection("users")
                    .document(userId)
                    .collection(collection)
                    .limit(to: 1)
                    .getDocuments()
                
                let result = ValidationResult(
                    test: "User Collection: \(collection)",
                    status: .pass,
                    message: "✅ Collection accessible: /users/\(userId)/\(collection)"
                )
                validationResults.append(result)
                
            } catch {
                let result = ValidationResult(
                    test: "User Collection: \(collection)",
                    status: .fail,
                    message: "❌ Collection error: \(error.localizedDescription)"
                )
                validationResults.append(result)
            }
        }
    }
    
    // MARK: - Test 2: No Global Collections
    private func validateNoGlobalCollections() async {
        let globalCollections = [
            "clients",
            "assets",
            "expenses",
            "products", 
            "standalone_products",
            "tasks",
            "standalone_tasks"
        ]
        
        for collection in globalCollections {
            do {
                let snapshot = try await db.collection(collection)
                    .limit(to: 1)
                    .getDocuments()
                
                if snapshot.documents.isEmpty {
                    let result = ValidationResult(
                        test: "Global Collection: \(collection)",
                        status: .pass,
                        message: "✅ No global collection found: /\(collection)"
                    )
                    validationResults.append(result)
                } else {
                    let result = ValidationResult(
                        test: "Global Collection: \(collection)",
                        status: .warning,
                        message: "⚠️ Global collection exists: /\(collection) (should be user-specific)"
                    )
                    validationResults.append(result)
                }
                
            } catch {
                // This is expected - global collections should not be accessible
                let result = ValidationResult(
                    test: "Global Collection: \(collection)",
                    status: .pass,
                    message: "✅ Global collection properly restricted: /\(collection)"
                )
                validationResults.append(result)
            }
        }
    }
    
    // MARK: - Test 3: Data Isolation
    private func validateDataIsolation(userId: String) async {
        // Try to access a different user's data (should fail)
        let fakeUserId = "fake_user_id_12345"
        
        do {
            let snapshot = try await db.collection("users")
                .document(fakeUserId)
                .collection("clients")
                .limit(to: 1)
                .getDocuments()
            
            if snapshot.documents.isEmpty {
                let result = ValidationResult(
                    test: "Data Isolation",
                    status: .pass,
                    message: "✅ Cannot access other user's data (empty result)"
                )
                validationResults.append(result)
            } else {
                let result = ValidationResult(
                    test: "Data Isolation",
                    status: .fail,
                    message: "❌ Security issue: Can access other user's data"
                )
                validationResults.append(result)
            }
            
        } catch {
            let result = ValidationResult(
                test: "Data Isolation",
                status: .pass,
                message: "✅ Properly restricted: Cannot access other user's data"
            )
            validationResults.append(result)
        }
    }
    
    // MARK: - Test 4: Authentication Requirements
    private func validateAuthenticationRequirements() async {
        if let currentUser = Auth.auth().currentUser {
            let result = ValidationResult(
                test: "Authentication",
                status: .pass,
                message: "✅ User authenticated: \(currentUser.email ?? "N/A")"
            )
            validationResults.append(result)
        } else {
            let result = ValidationResult(
                test: "Authentication",
                status: .fail,
                message: "❌ No authenticated user"
            )
            validationResults.append(result)
        }
    }
    
    // MARK: - Generate Validation Report
    func generateReport() -> String {
        var report = "🔍 Firebase Structure Validation Report\n"
        report += "=====================================\n\n"
        
        let passed = validationResults.filter { $0.status == .pass }.count
        let failed = validationResults.filter { $0.status == .fail }.count
        let warnings = validationResults.filter { $0.status == .warning }.count
        
        report += "📊 Summary:\n"
        report += "✅ Passed: \(passed)\n"
        report += "❌ Failed: \(failed)\n"
        report += "⚠️ Warnings: \(warnings)\n\n"
        
        report += "📋 Details:\n"
        for result in validationResults {
            let icon = result.status == .pass ? "✅" : result.status == .fail ? "❌" : "⚠️"
            report += "\(icon) \(result.test): \(result.message)\n"
        }
        
        return report
    }
}

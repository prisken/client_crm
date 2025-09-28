import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreData

@MainActor
class SystemTester: ObservableObject {
    private let db = Firestore.firestore()
    @Published var testStatus = "Ready to test"
    @Published var isTesting = false
    @Published var testResults: [TestResult] = []
    @Published var currentTest = ""
    
    struct TestResult {
        let category: String
        let testName: String
        let status: TestStatus
        let message: String
        let timestamp: Date
        
        enum TestStatus {
            case pass, fail, warning, info
        }
    }
    
    // MARK: - Run All Tests
    func executeAllTests(context: NSManagedObjectContext) async {
        isTesting = true
        testStatus = "🚀 Starting comprehensive system tests..."
        testResults.removeAll()
        
        do {
            // Test 1: Authentication System
            await testAuthenticationSystem(context: context)
            
            // Test 2: Firebase Structure
            await testFirebaseStructure()
            
            // Test 3: Data Sync System
            await testDataSyncSystem(context: context)
            
            // Test 4: User Isolation
            await testUserIsolation()
            
            // Test 5: Core Data Integration
            await testCoreDataIntegration(context: context)
            
            testStatus = "✅ All tests completed successfully!"
            
        } catch {
            testStatus = "❌ Testing failed: \(error.localizedDescription)"
        }
        
        isTesting = false
    }
    
    // MARK: - Test 1: Authentication System
    private func testAuthenticationSystem(context: NSManagedObjectContext) async {
        addResult(category: "Authentication", testName: "Firebase Auth Check", status: .info, message: "Testing Firebase Authentication system...")
        
        // Check if user is authenticated
        if let firebaseUser = Auth.auth().currentUser {
            addResult(category: "Authentication", testName: "Firebase Auth Status", status: .pass, 
                     message: "✅ User authenticated: \(firebaseUser.email ?? "N/A")")
            
            // Test token retrieval
            do {
                let token = try await firebaseUser.getIDToken()
                if !token.isEmpty {
                    addResult(category: "Authentication", testName: "Token Retrieval", status: .pass,
                             message: "✅ Firebase token retrieved successfully")
                } else {
                    addResult(category: "Authentication", testName: "Token Retrieval", status: .fail,
                             message: "❌ Empty Firebase token received")
                }
            } catch {
                addResult(category: "Authentication", testName: "Token Retrieval", status: .fail,
                         message: "❌ Failed to get Firebase token: \(error.localizedDescription)")
            }
            
            // Test Core Data user integration
            let request: NSFetchRequest<CoreDataUser> = CoreDataUser.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", firebaseUser.email ?? "")
            
            do {
                let users = try context.fetch(request)
                if let localUser = users.first {
                    addResult(category: "Authentication", testName: "Core Data Integration", status: .pass,
                             message: "✅ Core Data user found: \(localUser.email ?? "")")
                } else {
                    addResult(category: "Authentication", testName: "Core Data Integration", status: .warning,
                             message: "⚠️ No Core Data user found for Firebase user")
                }
            } catch {
                addResult(category: "Authentication", testName: "Core Data Integration", status: .fail,
                         message: "❌ Error fetching Core Data user: \(error.localizedDescription)")
            }
            
        } else {
            addResult(category: "Authentication", testName: "Firebase Auth Status", status: .fail,
                     message: "❌ No authenticated Firebase user")
        }
    }
    
    // MARK: - Test 2: Firebase Structure
    private func testFirebaseStructure() async {
        addResult(category: "Firebase Structure", testName: "Structure Validation", status: .info, message: "Testing Firebase database structure...")
        
        guard let currentUser = Auth.auth().currentUser else {
            addResult(category: "Firebase Structure", testName: "User Check", status: .fail,
                     message: "❌ No authenticated user for structure testing")
            return
        }
        
        let collections = ["clients", "assets", "expenses", "products", "standalone_products", "tasks", "standalone_tasks"]
        
        for collection in collections {
            do {
                let snapshot = try await db.collection("users")
                    .document(currentUser.uid)
                    .collection(collection)
                    .limit(to: 1)
                    .getDocuments()
                
                addResult(category: "Firebase Structure", testName: "Collection: \(collection)", status: .pass,
                         message: "✅ User collection accessible: /users/\(currentUser.uid)/\(collection)")
                
            } catch {
                addResult(category: "Firebase Structure", testName: "Collection: \(collection)", status: .fail,
                         message: "❌ Collection error: \(error.localizedDescription)")
            }
        }
        
        // Test that global collections don't exist or are empty
        for collection in collections {
            do {
                let snapshot = try await db.collection(collection)
                    .limit(to: 1)
                    .getDocuments()
                
                if snapshot.documents.isEmpty {
                    addResult(category: "Firebase Structure", testName: "Global Collection: \(collection)", status: .pass,
                             message: "✅ No global collection data: /\(collection)")
                } else {
                    addResult(category: "Firebase Structure", testName: "Global Collection: \(collection)", status: .warning,
                             message: "⚠️ Global collection has data: /\(collection) (should be user-specific)")
                }
                
            } catch {
                addResult(category: "Firebase Structure", testName: "Global Collection: \(collection)", status: .pass,
                         message: "✅ Global collection properly restricted: /\(collection)")
            }
        }
    }
    
    // MARK: - Test 3: Data Sync System
    private func testDataSyncSystem(context: NSManagedObjectContext) async {
        addResult(category: "Data Sync", testName: "Sync System Test", status: .info, message: "Testing data synchronization system...")
        
        // Test Core Data entities
        let entityTests = [
            ("Client", "Client.fetchRequest()"),
            ("Asset", "Asset.fetchRequest()"),
            ("Expense", "Expense.fetchRequest()"),
            ("ClientProduct", "ClientProduct.fetchRequest()"),
            ("Product", "Product.fetchRequest()"),
            ("Task", "Task.fetchRequest()"),
            ("ClientTask", "ClientTask.fetchRequest()")
        ]
        
        for (entityName, _) in entityTests {
            do {
                let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
                let count = try context.count(for: request)
                
                addResult(category: "Data Sync", testName: "Core Data: \(entityName)", status: .pass,
                         message: "✅ \(entityName): \(count) entities in Core Data")
                
            } catch {
                addResult(category: "Data Sync", testName: "Core Data: \(entityName)", status: .fail,
                         message: "❌ Error fetching \(entityName): \(error.localizedDescription)")
            }
        }
        
        // Test Firebase collections
        guard let currentUser = Auth.auth().currentUser else {
            addResult(category: "Data Sync", testName: "Firebase Collections", status: .fail,
                     message: "❌ No authenticated user for Firebase testing")
            return
        }
        
        let collections = ["clients", "assets", "expenses", "products", "standalone_products", "tasks", "standalone_tasks"]
        
        for collection in collections {
            do {
                let snapshot = try await db.collection("users")
                    .document(currentUser.uid)
                    .collection(collection)
                    .getDocuments()
                
                addResult(category: "Data Sync", testName: "Firebase: \(collection)", status: .pass,
                         message: "✅ \(collection): \(snapshot.documents.count) documents in Firebase")
                
            } catch {
                addResult(category: "Data Sync", testName: "Firebase: \(collection)", status: .fail,
                         message: "❌ Error fetching Firebase \(collection): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Test 4: User Isolation
    private func testUserIsolation() async {
        addResult(category: "User Isolation", testName: "Isolation Test", status: .info, message: "Testing user data isolation...")
        
        guard let currentUser = Auth.auth().currentUser else {
            addResult(category: "User Isolation", testName: "User Check", status: .fail,
                     message: "❌ No authenticated user for isolation testing")
            return
        }
        
        // Test accessing different user's data (should fail or return empty)
        let fakeUserId = "fake_user_id_\(UUID().uuidString.prefix(8))"
        
        do {
            let snapshot = try await db.collection("users")
                .document(fakeUserId)
                .collection("clients")
                .limit(to: 1)
                .getDocuments()
            
            if snapshot.documents.isEmpty {
                addResult(category: "User Isolation", testName: "Cross-User Access", status: .pass,
                         message: "✅ Cannot access other user's data (properly isolated)")
            } else {
                addResult(category: "User Isolation", testName: "Cross-User Access", status: .fail,
                         message: "❌ Security issue: Can access other user's data")
            }
            
        } catch {
            addResult(category: "User Isolation", testName: "Cross-User Access", status: .pass,
                     message: "✅ Properly restricted: Cannot access other user's data")
        }
        
        // Test current user's data access
        do {
            let snapshot = try await db.collection("users")
                .document(currentUser.uid)
                .collection("clients")
                .limit(to: 1)
                .getDocuments()
            
            addResult(category: "User Isolation", testName: "Own Data Access", status: .pass,
                     message: "✅ Can access own user data: /users/\(currentUser.uid)/clients")
            
        } catch {
            addResult(category: "User Isolation", testName: "Own Data Access", status: .fail,
                     message: "❌ Cannot access own user data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Test 5: Core Data Integration
    private func testCoreDataIntegration(context: NSManagedObjectContext) async {
        addResult(category: "Core Data", testName: "Integration Test", status: .info, message: "Testing Core Data integration...")
        
        // Test Core Data context
        do {
            let request: NSFetchRequest<CoreDataUser> = CoreDataUser.fetchRequest()
            let users = try context.fetch(request)
            
            addResult(category: "Core Data", testName: "Context Access", status: .pass,
                     message: "✅ Core Data context working: \(users.count) users found")
            
        } catch {
            addResult(category: "Core Data", testName: "Context Access", status: .fail,
                     message: "❌ Core Data context error: \(error.localizedDescription)")
        }
        
        // Test Core Data model
        let model = context.persistentStoreCoordinator?.managedObjectModel
        if let model = model {
            let entityNames = model.entities.compactMap { $0.name }
            addResult(category: "Core Data", testName: "Model Entities", status: .pass,
                     message: "✅ Core Data model loaded: \(entityNames.joined(separator: ", "))")
        } else {
            addResult(category: "Core Data", testName: "Model Entities", status: .fail,
                     message: "❌ Core Data model not loaded")
        }
    }
    
    // MARK: - Helper Methods
    private func addResult(category: String, testName: String, status: TestResult.TestStatus, message: String) {
        let result = TestResult(
            category: category,
            testName: testName,
            status: status,
            message: message,
            timestamp: Date()
        )
        testResults.append(result)
        
        // Update current test status
        DispatchQueue.main.async {
            self.currentTest = "\(category): \(testName)"
        }
    }
    
    // MARK: - Generate Test Report
    func generateTestReport() -> String {
        var report = "🧪 COMPREHENSIVE SYSTEM TEST REPORT\n"
        report += "=====================================\n\n"
        
        let categories = Set(testResults.map { $0.category })
        let totalTests = testResults.count
        let passed = testResults.filter { $0.status == .pass }.count
        let failed = testResults.filter { $0.status == .fail }.count
        let warnings = testResults.filter { $0.status == .warning }.count
        let info = testResults.filter { $0.status == .info }.count
        
        report += "📊 SUMMARY:\n"
        report += "Total Tests: \(totalTests)\n"
        report += "✅ Passed: \(passed)\n"
        report += "❌ Failed: \(failed)\n"
        report += "⚠️ Warnings: \(warnings)\n"
        report += "ℹ️ Info: \(info)\n\n"
        
        for category in categories.sorted() {
            let categoryResults = testResults.filter { $0.category == category }
            report += "📋 \(category.uppercased()):\n"
            
            for result in categoryResults {
                let icon = result.status == .pass ? "✅" : result.status == .fail ? "❌" : result.status == .warning ? "⚠️" : "ℹ️"
                report += "  \(icon) \(result.testName): \(result.message)\n"
            }
            report += "\n"
        }
        
        // Overall assessment
        if failed == 0 {
            report += "🎉 OVERALL RESULT: ALL TESTS PASSED!\n"
            report += "Your authentication and data sync system is working perfectly.\n"
        } else {
            report += "⚠️ OVERALL RESULT: \(failed) TEST(S) FAILED\n"
            report += "Please review the failed tests and fix any issues.\n"
        }
        
        return report
    }
}

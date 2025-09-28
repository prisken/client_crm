import Foundation
import FirebaseCore
import FirebaseFirestore
import SwiftUI
import Combine

@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isConnected = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkConnection()
    }
    
    // MARK: - Connection Status
    func checkConnection() {
        // Simple connection test
        db.collection("test").document("connection")
            .getDocument { [weak self] document, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.isConnected = false
                        self?.syncError = "Firebase connection failed: \(error.localizedDescription)"
                        print("❌ Firebase connection failed: \(error)")
                    } else {
                        self?.isConnected = true
                        self?.syncError = nil
                        print("✅ Firebase connected successfully")
                    }
                }
            }
    }
    
    // MARK: - Sync Operations
    func startSync() {
        guard isConnected else {
            syncError = "Firebase not connected"
            return
        }
        
        isSyncing = true
        syncError = nil
        
        // Simulate sync process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
    }
    
    func forceSync() {
        guard isConnected else {
            syncError = "Please check your internet connection"
            return
        }
        
        startSync()
    }
    
    // MARK: - Data Operations
    func syncClient(_ client: Client) {
        guard let clientId = client.id?.uuidString else { return }
        
        let clientData: [String: Any] = [
            "id": clientId,
            "firstName": client.firstName ?? "",
            "lastName": client.lastName ?? "",
            "phone": client.phone ?? "",
            "email": client.email ?? "",
            "address": client.address ?? "",
            "notes": client.notes ?? "",
            "createdAt": client.createdAt ?? Date(),
            "updatedAt": client.updatedAt ?? Date(),
            "interests": client.interests as? [String] ?? [],
            "socialStatus": client.socialStatus as? [String] ?? [],
            "lifeStage": client.lifeStage as? [String] ?? [],
            "whatsappOptIn": client.whatsappOptIn,
            "whatsappOptInDate": client.whatsappOptInDate ?? Date()
        ]
        
        db.collection("clients").document(clientId).setData(clientData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing client: \(error)")
                    self?.syncError = "Failed to sync client: \(error.localizedDescription)"
                } else {
                    print("✅ Client synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncAsset(_ asset: Asset) {
        guard let assetId = asset.id?.uuidString else { return }
        
        let assetData: [String: Any] = [
            "id": assetId,
            "name": asset.name ?? "",
            "type": asset.type ?? "",
            "amount": asset.amount?.doubleValue ?? 0,
            "description": asset.assetDescription ?? "",
            "clientId": asset.client?.id?.uuidString ?? "",
            "createdAt": asset.createdAt ?? Date(),
            "updatedAt": asset.updatedAt ?? Date()
        ]
        
        db.collection("assets").document(assetId).setData(assetData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing asset: \(error)")
                    self?.syncError = "Failed to sync asset: \(error.localizedDescription)"
                } else {
                    print("✅ Asset synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncExpense(_ expense: Expense) {
        guard let expenseId = expense.id?.uuidString else { return }
        
        let expenseData: [String: Any] = [
            "id": expenseId,
            "name": expense.name ?? "",
            "type": expense.type ?? "",
            "amount": expense.amount?.doubleValue ?? 0,
            "frequency": expense.frequency ?? "",
            "description": expense.assetDescription ?? "",
            "clientId": expense.client?.id?.uuidString ?? "",
            "createdAt": expense.createdAt ?? Date(),
            "updatedAt": expense.updatedAt ?? Date()
        ]
        
        db.collection("expenses").document(expenseId).setData(expenseData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing expense: \(error)")
                    self?.syncError = "Failed to sync expense: \(error.localizedDescription)"
                } else {
                    print("✅ Expense synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
    
    func syncProduct(_ product: ClientProduct) {
        guard let productId = product.id?.uuidString else { return }
        
        let productData: [String: Any] = [
            "id": productId,
            "name": product.name ?? "",
            "category": product.category ?? "",
            "amount": product.amount?.doubleValue ?? 0,
            "premium": product.premium?.doubleValue ?? 0,
            "coverage": product.coverage ?? "",
            "status": product.status ?? "",
            "description": product.assetDescription ?? "",
            "clientId": product.client?.id?.uuidString ?? "",
            "createdAt": product.createdAt ?? Date(),
            "updatedAt": product.updatedAt ?? Date()
        ]
        
        db.collection("products").document(productId).setData(productData) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Error syncing product: \(error)")
                    self?.syncError = "Failed to sync product: \(error.localizedDescription)"
                } else {
                    print("✅ Product synced successfully")
                    self?.lastSyncDate = Date()
                }
            }
        }
    }
}

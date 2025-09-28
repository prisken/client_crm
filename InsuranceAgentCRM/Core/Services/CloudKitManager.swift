import CloudKit
import SwiftUI
import Combine
import Foundation

@MainActor
class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    
    @Published var isSignedIn = false
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    
    private let container = CKContainer(identifier: "iCloud.com.insuranceagent.crm.InsuranceAgentCRM")
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAccountStatus()
        setupRemoteChangeNotifications()
    }
    
    // MARK: - Account Status
    func checkAccountStatus() {
        container.accountStatus { [weak self] accountStatus, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.isSignedIn = false
                    self.syncError = "Error checking iCloud status: \(error.localizedDescription)"
                    print("❌ Error checking iCloud status: \(error)")
                    return
                }
                
                switch accountStatus {
                case .available:
                    self.isSignedIn = true
                    self.syncError = nil
                    print("✅ iCloud account available")
                case .noAccount:
                    self.isSignedIn = false
                    self.syncError = "No iCloud account found. Please sign in to iCloud in Settings."
                    print("❌ No iCloud account")
                case .restricted:
                    self.isSignedIn = false
                    self.syncError = "iCloud account is restricted."
                    print("❌ iCloud account restricted")
                case .couldNotDetermine:
                    self.isSignedIn = false
                    self.syncError = "Could not determine iCloud status."
                    print("❌ Could not determine iCloud status")
                @unknown default:
                    self.isSignedIn = false
                    self.syncError = "Unknown iCloud status."
                    print("❌ Unknown iCloud status")
                }
            }
        }
    }
    
    // MARK: - Sync Status
    func startSync() {
        isSyncing = true
        syncError = nil
        
        // Simulate sync process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isSyncing = false
            self.lastSyncDate = Date()
        }
    }
    
    // MARK: - Remote Change Notifications
    private func setupRemoteChangeNotifications() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .sink { [weak self] _ in
                self?.handleRemoteChange()
            }
            .store(in: &cancellables)
    }
    
    private func handleRemoteChange() {
        print("🔄 Remote change detected - syncing data")
        startSync()
    }
    
    // MARK: - Force Sync
    func forceSync() {
        guard isSignedIn else {
            syncError = "Please sign in to iCloud to sync data"
            return
        }
        
        startSync()
    }
    
    // MARK: - Reset Sync
    func resetSync() {
        lastSyncDate = nil
        syncError = nil
        checkAccountStatus()
    }
    
}

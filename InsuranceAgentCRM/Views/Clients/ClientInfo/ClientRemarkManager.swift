import SwiftUI
import CoreData

// MARK: - Client Remark Manager
class ClientRemarkManager: ObservableObject {
    @Published var remarks: [ClientRemark] = []
    private let context: NSManagedObjectContext
    private let firebaseManager: FirebaseManager
    
    init(context: NSManagedObjectContext, firebaseManager: FirebaseManager) {
        self.context = context
        self.firebaseManager = firebaseManager
    }
    
    func loadRemarks(for client: Client) {
        if let clientRemarks = client.remarks as? Set<ClientRemark> {
            remarks = Array(clientRemarks).sorted { $0.createdAt ?? Date() > $1.createdAt ?? Date() }
        } else {
            remarks = []
        }
    }
    
    func addRemark(content: String, to client: Client) {
        let remark = ClientRemark(context: context)
        remark.id = UUID()
        remark.content = content
        remark.createdAt = Date()
        remark.updatedAt = Date()
        remark.client = client
        
        do {
            try context.save()
            
            // Sync remark to Firebase
            DispatchQueue.main.async {
                self.firebaseManager.syncClientRemark(remark)
            }
            
            loadRemarks(for: client)
            print("✅ New remark added to client: \(client.displayName)")
        } catch {
            print("❌ Error adding client remark: \(error)")
        }
    }
    
    func updateRemark(_ remark: ClientRemark, newContent: String) {
        remark.content = newContent
        remark.updatedAt = Date()
        
        do {
            try context.save()
            
            // Sync updated remark to Firebase
            DispatchQueue.main.async {
                self.firebaseManager.syncClientRemark(remark)
            }
            
            print("✅ Client remark updated: \(remark.content ?? "Unknown")")
        } catch {
            print("❌ Error updating client remark: \(error)")
        }
    }
    
    func deleteRemark(_ remark: ClientRemark) {
        context.delete(remark)
        
        do {
            try context.save()
            print("✅ Client remark deleted")
        } catch {
            print("❌ Error deleting client remark: \(error)")
        }
    }
}

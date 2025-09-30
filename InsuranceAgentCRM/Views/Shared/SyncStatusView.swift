import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var firebaseManager: FirebaseManager
    
    var body: some View {
        HStack(spacing: 8) {
            // Connection Status Icon
            Image(systemName: connectionIcon)
                .foregroundColor(connectionColor)
                .font(.system(size: 14, weight: .medium))
            
            // Status Text
            Text(statusText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(statusColor)
            
            // Pending Count Badge
            if firebaseManager.pendingSyncCount > 0 {
                Text("\(firebaseManager.pendingSyncCount)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Color.orange)
                    .clipShape(Circle())
            }
            
            // Sync Progress Indicator
            if firebaseManager.isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var connectionIcon: String {
        if firebaseManager.isConnected {
            return "wifi"
        } else {
            return "wifi.slash"
        }
    }
    
    private var connectionColor: Color {
        if firebaseManager.isConnected {
            return .green
        } else {
            return .red
        }
    }
    
    private var statusText: String {
        if firebaseManager.isSyncing {
            return "Syncing..."
        } else if firebaseManager.isConnected {
            if firebaseManager.pendingSyncCount > 0 {
                return "Pending: \(firebaseManager.pendingSyncCount)"
            } else {
                return "Connected"
            }
        } else {
            return "Offline"
        }
    }
    
    private var statusColor: Color {
        if firebaseManager.isSyncing {
            return .blue
        } else if firebaseManager.isConnected {
            return .primary
        } else {
            return .red
        }
    }
    
    private var backgroundColor: Color {
        if firebaseManager.isSyncing {
            return Color.blue.opacity(0.1)
        } else if firebaseManager.isConnected {
            return Color.green.opacity(0.1)
        } else {
            return Color.red.opacity(0.1)
        }
    }
}

// MARK: - Sync Status Button
struct SyncStatusButton: View {
    @ObservedObject var firebaseManager: FirebaseManager
    
    var body: some View {
        Button(action: {
            if firebaseManager.isConnected {
                firebaseManager.forceSync()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: syncIcon)
                    .font(.system(size: 14, weight: .medium))
                
                Text("Sync")
                    .font(.system(size: 12, weight: .medium))
                
                if firebaseManager.pendingSyncCount > 0 {
                    Text("(\(firebaseManager.pendingSyncCount))")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            .foregroundColor(buttonColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(buttonBackground)
            .cornerRadius(6)
        }
        .disabled(firebaseManager.isSyncing || !firebaseManager.isConnected)
    }
    
    private var syncIcon: String {
        if firebaseManager.isSyncing {
            return "arrow.clockwise"
        } else if firebaseManager.isConnected {
            return "arrow.clockwise"
        } else {
            return "wifi.slash"
        }
    }
    
    private var buttonColor: Color {
        if firebaseManager.isSyncing {
            return .blue
        } else if firebaseManager.isConnected {
            return .primary
        } else {
            return .gray
        }
    }
    
    private var buttonBackground: Color {
        if firebaseManager.isSyncing {
            return Color.blue.opacity(0.1)
        } else if firebaseManager.isConnected {
            return Color.gray.opacity(0.1)
        } else {
            return Color.gray.opacity(0.05)
        }
    }
}

// MARK: - Preview
struct SyncStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            // Connected with no pending changes
            SyncStatusView(firebaseManager: createMockManager(connected: true, syncing: false, pending: 0))
            
            // Connected with pending changes
            SyncStatusView(firebaseManager: createMockManager(connected: true, syncing: false, pending: 3))
            
            // Syncing
            SyncStatusView(firebaseManager: createMockManager(connected: true, syncing: true, pending: 2))
            
            // Offline
            SyncStatusView(firebaseManager: createMockManager(connected: false, syncing: false, pending: 5))
            
            Divider()
            
            // Sync Button
            SyncStatusButton(firebaseManager: createMockManager(connected: true, syncing: false, pending: 3))
        }
        .padding()
    }
    
    private static func createMockManager(connected: Bool, syncing: Bool, pending: Int) -> FirebaseManager {
        let manager = FirebaseManager.shared
        manager.isConnected = connected
        manager.isSyncing = syncing
        manager.pendingSyncCount = pending
        return manager
    }
}
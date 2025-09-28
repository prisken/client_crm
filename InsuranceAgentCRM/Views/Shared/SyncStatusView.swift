import SwiftUI

struct SyncStatusView: View {
    @StateObject private var cloudKitManager = CloudKitManager.shared
    @State private var showingSyncAlert = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Sync Status Icon
            Group {
                if cloudKitManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if cloudKitManager.isSignedIn {
                    Image(systemName: "icloud.fill")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "icloud.slash")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 16, height: 16)
            
            // Sync Status Text
            VStack(alignment: .leading, spacing: 2) {
                Text(syncStatusText)
                    .font(.caption)
                    .foregroundColor(syncStatusColor)
                
                if let lastSync = cloudKitManager.lastSyncDate {
                    Text("Last sync: \(lastSync, formatter: timeFormatter)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Manual Sync Button
            if cloudKitManager.isSignedIn {
                Button(action: {
                    cloudKitManager.forceSync()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .disabled(cloudKitManager.isSyncing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .onTapGesture {
            if !cloudKitManager.isSignedIn {
                showingSyncAlert = true
            }
        }
        .alert("iCloud Sync", isPresented: $showingSyncAlert) {
            Button("Settings") {
                openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please sign in to iCloud in Settings to enable data sync across your devices.")
        }
    }
    
    private var syncStatusText: String {
        if cloudKitManager.isSyncing {
            return "Syncing..."
        } else if cloudKitManager.isSignedIn {
            return "iCloud Sync"
        } else {
            return "iCloud Unavailable"
        }
    }
    
    private var syncStatusColor: Color {
        if cloudKitManager.isSyncing {
            return .blue
        } else if cloudKitManager.isSignedIn {
            return .green
        } else {
            return .red
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
}

#Preview {
    VStack {
        SyncStatusView()
        Spacer()
    }
    .padding()
}

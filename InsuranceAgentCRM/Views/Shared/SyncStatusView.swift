import SwiftUI

struct SyncStatusView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var showingSyncAlert = false
    
    var body: some View {
        HStack(spacing: 8) {
            // Sync Status Icon
            Group {
                if firebaseManager.isSyncing {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if firebaseManager.isConnected {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                } else {
                    Image(systemName: "wifi.slash")
                        .foregroundColor(.red)
                }
            }
            .frame(width: 16, height: 16)
            
            // Sync Status Text
            VStack(alignment: .leading, spacing: 2) {
                Text(syncStatusText)
                    .font(.caption)
                    .foregroundColor(syncStatusColor)
                
                if let lastSync = firebaseManager.lastSyncDate {
                    Text("Last sync: \(lastSync, formatter: timeFormatter)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Manual Sync Button
            if firebaseManager.isConnected {
                Button(action: {
                    firebaseManager.forceSync()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .disabled(firebaseManager.isSyncing)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .onTapGesture {
            if !firebaseManager.isConnected {
                showingSyncAlert = true
            }
        }
        .alert("Firebase Sync", isPresented: $showingSyncAlert) {
            Button("Check Connection") {
                firebaseManager.checkConnection()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Firebase sync is not connected. Please check your internet connection and try again.")
        }
    }
    
    private var syncStatusText: String {
        if firebaseManager.isSyncing {
            return "Syncing..."
        } else if firebaseManager.isConnected {
            return "Firebase Sync"
        } else {
            return "Firebase Unavailable"
        }
    }
    
    private var syncStatusColor: Color {
        if firebaseManager.isSyncing {
            return .orange
        } else if firebaseManager.isConnected {
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

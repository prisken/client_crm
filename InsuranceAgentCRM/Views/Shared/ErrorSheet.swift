import SwiftUI

// MARK: - Error Sheet
struct ErrorSheet: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                
                Text("Item Not Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Button("Close") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Error")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ErrorSheet(message: "Asset not found", onDismiss: {})
}

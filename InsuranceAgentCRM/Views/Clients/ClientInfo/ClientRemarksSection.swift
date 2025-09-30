import SwiftUI
import CoreData

// MARK: - Client Remarks Section
struct ClientRemarksSection: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var remarkManager: ClientRemarkManager
    @State private var showingAddRemark = false
    @State private var newRemark = ""
    @State private var selectedRemark: ClientRemark?
    @State private var showingEditRemark = false
    @State private var editingRemark = ""
    
    init(client: Client) {
        self.client = client
        self._remarkManager = StateObject(wrappedValue: ClientRemarkManager(context: PersistenceController.shared.container.viewContext, firebaseManager: FirebaseManager.shared))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Client Remarks & Notes")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Add notes, observations, and follow-up reminders for this client")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Add Remark") {
                    showingAddRemark = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if remarkManager.remarks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No remarks added yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Add your first remark to track important notes about this client")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(remarkManager.remarks) { remark in
                        ClientRemarkRowView(
                            remark: remark,
                            onEdit: {
                                selectedRemark = remark
                                editingRemark = remark.content ?? ""
                                showingEditRemark = true
                            },
                            onDelete: {
                                remarkManager.deleteRemark(remark)
                                remarkManager.loadRemarks(for: client)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onAppear {
            remarkManager.loadRemarks(for: client)
        }
        .sheet(isPresented: $showingAddRemark) {
            AddClientRemarkSheet(
                newRemark: $newRemark,
                onSave: {
                    remarkManager.addRemark(content: newRemark, to: client)
                    newRemark = ""
                }
            )
        }
        .sheet(isPresented: $showingEditRemark) {
            EditClientRemarkSheet(
                remark: $editingRemark,
                onSave: {
                    if let selectedRemark = selectedRemark {
                        remarkManager.updateRemark(selectedRemark, newContent: editingRemark)
                        remarkManager.loadRemarks(for: client)
                    }
                }
            )
        }
    }
}

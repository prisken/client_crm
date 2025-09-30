import SwiftUI
import CoreData

// MARK: - Client Remark Row View
struct ClientRemarkRowView: View {
    let remark: ClientRemark
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(remark.content ?? "")
                    .font(.body)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("Created: \(remark.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let updatedAt = remark.updatedAt, updatedAt != remark.createdAt {
                        Text("• Updated: \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .confirmationDialog("Delete Remark", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this remark?")
        }
    }
}

// MARK: - Add Client Remark Sheet
struct AddClientRemarkSheet: View {
    @Binding var newRemark: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Add Client Remark")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                TextField("Enter your remark", text: $newRemark, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(5...10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Remark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onSave()
                        dismiss()
                    }
                    .disabled(newRemark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            })
        }
    }
}

// MARK: - Edit Client Remark Sheet
struct EditClientRemarkSheet: View {
    @Binding var remark: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Edit Client Remark")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                TextField("Edit your remark", text: $remark, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(5...10)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Remark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                    .disabled(remark.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            })
        }
    }
}

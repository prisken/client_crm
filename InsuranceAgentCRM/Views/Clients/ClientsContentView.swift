 import SwiftUI
import CoreData

struct ClientsContentView: View {
    @ObservedObject var viewModel: ClientsViewModel
    let searchText: String
    @Binding var selectedClient: Client?
    let onDeleteClient: (Client) -> Void
    
    var body: some View {
        // Responsive Layout - iPhone vs iPad
        if DeviceInfo.isIPhone {
            // iPhone: Stack navigation with enhanced mobile UX
            NavigationStack {
                ClientsListView(
                    viewModel: viewModel,
                    searchText: searchText,
                    selectedClient: $selectedClient,
                    onDeleteClient: onDeleteClient
                )
                .navigationTitle("Clients")
                .navigationBarTitleDisplayMode(DeviceInfo.isIPhone ? .inline : .large)
                .navigationDestination(isPresented: .constant(selectedClient != nil)) {
                    if let client = selectedClient {
                        ClientDetailView(client: client)
                            .environment(\.managedObjectContext, viewModel.context)
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle(client.firstName ?? "Client")
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button(action: {
                                        // Edit client action
                                    }) {
                                        Image(systemName: "pencil")
                                            .font(.system(size: DeviceInfo.compactIconSize, weight: .medium))
                                    }
                                    .mobileTouchTarget()
                                }
                            }
                            .onDisappear {
                                // Clear selection when navigating back
                                selectedClient = nil
                            }
                    }
                }
            }
        } else {
            // iPad: Enhanced Split view with superior UX
            HStack(spacing: 0) {
                // Left Side - Compact Clients List
                VStack(spacing: 0) {
                    // Compact Header Section
                    VStack(spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Clients")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("\(viewModel.clients.count) total")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Compact Add Button
                            Button(action: {
                                // Add new client action
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .semibold))
                                    Text("Add")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Compact Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.system(size: 14))
                            
                            TextField("Search clients...", text: .constant(searchText))
                                .font(.system(size: 14))
                                .textFieldStyle(PlainTextFieldStyle())
                            
                            if !searchText.isEmpty {
                                Button(action: {
                                    // Clear search
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    
                    // Divider with subtle styling
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 1)
                        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    
                    // Clients List with enhanced styling
                    ClientsListView(
                        viewModel: viewModel,
                        searchText: searchText,
                        selectedClient: $selectedClient,
                        onDeleteClient: onDeleteClient
                    )
                    .background(Color(.systemGray6))
                }
                .frame(minWidth: 420, maxWidth: 520)
                .background(Color(.systemGray6))
                
                // Enhanced Divider
                ZStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 1)
                    
                    // Resize handle
                    Rectangle()
                        .fill(Color(.systemGray3))
                        .frame(width: 8)
                        .opacity(0)
                        .contentShape(Rectangle())
                        .onHover { isHovering in
                            // Add hover effects for resize handle
                        }
                }
                
                // Right Side - Enhanced Client Details with clear visual hierarchy
                VStack(spacing: 0) {
                    if let client = selectedClient {
                        // Compact Client Header
                        VStack(spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    HStack(spacing: 12) {
                                        if let email = client.email {
                                            HStack(spacing: 4) {
                                                Image(systemName: "envelope.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.system(size: 12))
                                                Text(email)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        if let phone = client.phone {
                                            HStack(spacing: 4) {
                                                Image(systemName: "phone.fill")
                                                    .foregroundColor(.green)
                                                    .font(.system(size: 12))
                                                Text(phone)
                                                    .font(.system(size: 13, weight: .medium))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                // Compact Action Buttons
                                HStack(spacing: 8) {
                                    Button(action: {
                                        // Edit client action
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "pencil")
                                                .font(.system(size: 14, weight: .medium))
                                            Text("Edit")
                                                .font(.system(size: 14, weight: .semibold))
                                        }
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    
                                    Button(action: {
                                        // More actions
                                    }) {
                                        Image(systemName: "ellipsis.circle")
                                            .font(.system(size: 18))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            
                            // Status Indicators
                            HStack(spacing: 12) {
                                StatusBadge(
                                    title: client.isActive ? "Active" : "Inactive",
                                    color: client.isActive ? .green : .orange
                                )
                                
                                if let tags = client.tags as? [String], !tags.isEmpty {
                                    ForEach(tags.prefix(3), id: \.self) { tag in
                                        TagBadge(tag: tag)
                                    }
                                    
                                    if tags.count > 3 {
                                        Text("+\(tags.count - 3)")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color(.systemGray5))
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                        .overlay(
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 1),
                            alignment: .bottom
                        )
                        
                        // Client Details Content
                        ClientDetailView(client: client)
                            .environment(\.managedObjectContext, viewModel.context)
                            .background(Color(.systemBackground))
                    } else {
                        EnhancedEmptyClientDetailView()
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemBackground))
            }
        }
    }
}

// MARK: - Enhanced Empty State for iPad
struct EnhancedEmptyClientDetailView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Enhanced Visual with better spacing
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.1), .blue.opacity(0.05)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .blue.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Select a Client")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Choose a client from the list to view their details, manage tasks, and track their insurance journey")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, 60)
                }
            }
            
            // Quick Tips Section
            VStack(spacing: 16) {
                Text("Quick Tips")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                VStack(spacing: 12) {
                    TipRow(icon: "magnifyingglass", text: "Use the search bar to quickly find clients")
                    TipRow(icon: "tag.fill", text: "Filter clients by tags and status")
                    TipRow(icon: "plus.circle.fill", text: "Add new clients with the + button")
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemBackground), Color(.systemGray6).opacity(0.3)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Supporting Components
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let count: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
            
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .foregroundColor(isSelected ? .white : .secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            isSelected ? 
            LinearGradient(gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]), startPoint: .leading, endPoint: .trailing) :
            LinearGradient(gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray6)]), startPoint: .leading, endPoint: .trailing)
        )
        .cornerRadius(20)
        .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
    }
}

struct StatusBadge: View {
    let title: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TagBadge: View {
    let tag: String
    
    var body: some View {
        Text(tag)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Legacy Empty View (kept for compatibility)
struct EmptyClientDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.circle")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("Select a Client")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Choose a client from the list to view their details and manage follow-ups")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}


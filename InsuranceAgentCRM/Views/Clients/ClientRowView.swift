import SwiftUI

struct ClientRowView: View {
    let client: Client
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DeviceInfo.isIPhone ? 16 : 12) {
                // Avatar
                ClientAvatarView(client: client)
                
                // Client Info
                VStack(alignment: .leading, spacing: DeviceInfo.isIPhone ? 8 : 6) {
                    Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                        .font(.system(size: DeviceInfo.isIPhone ? 18 : 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let email = client.email {
                        HStack(spacing: 6) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: DeviceInfo.isIPhone ? 12 : 10))
                                .foregroundColor(.secondary)
                            Text(email)
                                .font(.system(size: DeviceInfo.isIPhone ? 15 : 14))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: DeviceInfo.isIPhone ? 12 : 10))
                            .foregroundColor(.secondary)
                        Text(client.phone ?? "")
                            .font(.system(size: DeviceInfo.isIPhone ? 15 : 14))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    if let tags = client.tags as? [String], !tags.isEmpty {
                        ClientTagsView(tags: tags)
                    }
                }
                
                Spacer()
                
                // Status indicators
                ClientStatusIndicatorsView(client: client)
            }
            .padding(.horizontal, DeviceInfo.mobilePadding)
            .padding(.vertical, DeviceInfo.isIPhone ? 16 : 12)
            .mobileTouchTarget()
            .background(Color(.systemBackground))
            .cornerRadius(DeviceInfo.mobileCornerRadius)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ClientAvatarView: View {
    let client: Client
    
    var body: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .frame(
                width: DeviceInfo.isIPhone ? 64 : 60, 
                height: DeviceInfo.isIPhone ? 64 : 60
            )
            .overlay(
                Text(initials)
                    .font(.system(
                        size: DeviceInfo.isIPhone ? 24 : 20, 
                        weight: .semibold
                    ))
                    .foregroundColor(.blue)
            )
    }
    
    private var initials: String {
        let first = client.firstName?.prefix(1) ?? ""
        let last = client.lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
}

struct ClientTagsView: View {
    let tags: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(tags.prefix(2), id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            if tags.count > 2 {
                Text("+\(tags.count - 2)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ClientStatusIndicatorsView: View {
    let client: Client
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            if client.whatsappOptIn {
                HStack(spacing: 4) {
                    Image(systemName: "message.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("WhatsApp")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            if let updatedAt = client.updatedAt {
                let daysSince = Calendar.current.dateComponents([.day], from: updatedAt, to: Date()).day ?? 0
                Text(daysSince == 0 ? "Today" : "\(daysSince)d ago")
                    .font(.caption2)
                    .foregroundColor(daysSince > 7 ? .orange : .secondary)
            }
        }
    }
}


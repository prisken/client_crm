import Foundation
import SwiftUI

class WhatsAppService: ObservableObject {
    @Published var isConnected = false
    @Published var messageTemplates: [MessageTemplate] = []
    @Published var recentMessages: [WhatsAppMessage] = []
    
    private let baseURL = "https://your-serverless-backend.com" // Replace with actual URL
    private let apiKey = "your-api-key" // Replace with actual API key
    
    init() {
        loadMessageTemplates()
        checkConnection()
    }
    
    // MARK: - Connection Management
    func checkConnection() {
        // In a real implementation, this would ping the WhatsApp Business API
        // For now, we'll simulate a connection check
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isConnected = true
        }
    }
    
    // MARK: - Message Templates
    func loadMessageTemplates() {
        // Load templates from Core Data
        // This would be implemented with a Core Data fetch
    }
    
    func createTemplate(name: String, body: String) async throws -> MessageTemplate {
        // Create a new message template
        // This would save to Core Data and sync with WhatsApp Business API
        throw WhatsAppError.notImplemented
    }
    
    // MARK: - Send Messages
    func sendMessage(
        to client: Client,
        template: MessageTemplate,
        variables: [String: String] = [:]
    ) async throws -> WhatsAppMessage {
        
        guard isConnected else {
            throw WhatsAppError.notConnected
        }
        
        guard client.whatsappOptIn else {
            throw WhatsAppError.clientNotOptedIn
        }
        
        // Prepare message content with variable substitution
        let content = substituteVariables(in: template.body ?? "", with: variables)
        
        // Create message payload
        let payload = WhatsAppMessagePayload(
            to: client.phone ?? "",
            template: template.name ?? "",
            variables: variables,
            content: content
        )
        
        // Send to serverless backend
        _ = try await sendToBackend(payload: payload)
        
        // Save to Core Data
        let whatsappMessage = WhatsAppMessage()
        whatsappMessage.id = UUID()
        whatsappMessage.client = client
        whatsappMessage.template = template
        whatsappMessage.content = content
        whatsappMessage.sentAt = Date()
        whatsappMessage.status = "sent"
        whatsappMessage.createdAt = Date()
        
        return whatsappMessage
    }
    
    // MARK: - Message Status
    func checkMessageStatus(messageId: UUID) async throws -> MessageStatus {
        let url = URL(string: "\(baseURL)/whatsapp/status/\(messageId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let status = try JSONDecoder().decode(MessageStatus.self, from: data)
        
        return status
    }
    
    // MARK: - Helper Functions
    private func substituteVariables(in template: String, with variables: [String: String]) -> String {
        var result = template
        
        for (key, value) in variables {
            let placeholder = "{{\(key)}}"
            result = result.replacingOccurrences(of: placeholder, with: value)
        }
        
        return result
    }
    
    private func sendToBackend(payload: WhatsAppMessagePayload) async throws -> WhatsAppMessage {
        let url = URL(string: "\(baseURL)/whatsapp/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let jsonData = try JSONEncoder().encode(payload)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw WhatsAppError.sendFailed
        }
        
        let whatsAppResponse = try JSONDecoder().decode(WhatsAppResponse.self, from: data)
        
        // Create WhatsApp message object
        let message = WhatsAppMessage()
        message.id = UUID(uuidString: whatsAppResponse.messageId) ?? UUID()
        message.status = whatsAppResponse.status
        message.sentAt = ISO8601DateFormatter().date(from: whatsAppResponse.sentAt) ?? Date()
        
        return message
    }
}

// MARK: - Data Models
struct WhatsAppMessagePayload: Codable {
    let to: String
    let template: String
    let variables: [String: String]
    let content: String
}

struct WhatsAppResponse: Codable {
    let messageId: String
    let status: String
    let sentAt: String
}

struct MessageStatus: Codable {
    let status: String
    let deliveredAt: String?
    let readAt: String?
}

// MARK: - Errors
enum WhatsAppError: LocalizedError {
    case notConnected
    case clientNotOptedIn
    case sendFailed
    case notImplemented
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "WhatsApp service is not connected"
        case .clientNotOptedIn:
            return "Client has not opted in to WhatsApp messages"
        case .sendFailed:
            return "Failed to send WhatsApp message"
        case .notImplemented:
            return "Feature not yet implemented"
        }
    }
}

// MARK: - WhatsApp Message View
struct WhatsAppMessageView: View {
    let client: Client
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var whatsappService = WhatsAppService()
    
    @State private var selectedTemplate: MessageTemplate?
    @State private var messageContent = ""
    @State private var variables: [String: String] = [:]
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingTemplates = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Client Info
                HStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text(initials)
                                .font(.headline)
                                .foregroundColor(.green)
                        )
                    
                    VStack(alignment: .leading) {
                        Text("\(client.firstName ?? "") \(client.lastName ?? "")")
                            .font(.headline)
                        Text(client.phone ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if client.whatsappOptIn {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if !client.whatsappOptIn {
                    Text("This client has not opted in to WhatsApp messages")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Template Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message Template")
                        .font(.headline)
                    
                    if let template = selectedTemplate {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name ?? "")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(template.body ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    } else {
                        Button("Select Template") {
                            showingTemplates = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                // Message Preview
                if !messageContent.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message Preview")
                            .font(.headline)
                        
                        Text(messageContent)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                // Variables
                if !variables.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Variables")
                            .font(.headline)
                        
                        ForEach(Array(variables.keys.sorted()), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                TextField("Value", text: Binding(
                                    get: { variables[key] ?? "" },
                                    set: { variables[key] = $0 }
                                ))
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Error Message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Send Button
                Button(action: sendMessage) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text("Send WhatsApp Message")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(client.whatsappOptIn ? Color.green : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!client.whatsappOptIn || selectedTemplate == nil || isLoading)
            }
            .padding()
            .navigationTitle("WhatsApp Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingTemplates) {
            MessageTemplatesView(selectedTemplate: $selectedTemplate)
                .environment(\.managedObjectContext, viewContext)
        }
        .onChange(of: selectedTemplate) {
            updateMessageContent()
        }
        .onChange(of: variables) {
            updateMessageContent()
        }
    }
    
    private var initials: String {
        let first = client.firstName?.prefix(1) ?? ""
        let last = client.lastName?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }
    
    private func updateMessageContent() {
        guard let template = selectedTemplate else {
            messageContent = ""
            return
        }
        
        var content = template.body ?? ""
        
        for (key, value) in variables {
            let placeholder = "{{\(key)}}"
            content = content.replacingOccurrences(of: placeholder, with: value)
        }
        
        messageContent = content
    }
    
    private func sendMessage() {
        guard let template = selectedTemplate else { return }
        
        isLoading = true
        errorMessage = ""
        
        _Concurrency.Task {
            do {
                _ = try await whatsappService.sendMessage(
                    to: client,
                    template: template,
                    variables: variables
                )
                
                // Save to Core Data
                try viewContext.save()
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

struct MessageTemplatesView: View {
    @Binding var selectedTemplate: MessageTemplate?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MessageTemplate.name, ascending: true)]
    ) private var templates: FetchedResults<MessageTemplate>
    
    var body: some View {
        NavigationView {
            List {
                ForEach(templates, id: \.self) { template in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(template.name ?? "")
                            .font(.headline)
                        
                        Text(template.body ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 4)
                    .onTapGesture {
                        selectedTemplate = template
                        dismiss()
                    }
                }
            }
            .navigationTitle("Message Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WhatsAppMessageView(client: Client())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}



import SwiftUI
import CoreData
import PDFKit

struct ReportsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel = ReportsViewModel()
    @State private var selectedReportType: ReportType = .clientList
    @State private var showingExportOptions = false
    @State private var exportFormat: ExportFormat = .csv
    
    enum ReportType: String, CaseIterable {
        case clientList = "Client List"
        case monthlyCommission = "Monthly Commission"
        case renewalRate = "Renewal Rate"
        case followUpConversion = "Follow-up Conversion"
        case custom = "Custom Report"
    }
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case excel = "Excel"
        case pdf = "PDF"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Report Type Picker
                Picker("Report Type", selection: $selectedReportType) {
                    ForEach(ReportType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Report Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Report Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(selectedReportType.rawValue)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Generated on \(Date().formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Report Data
                        switch selectedReportType {
                        case .clientList:
                            ClientListReportView(data: viewModel.clientListData)
                        case .monthlyCommission:
                            MonthlyCommissionReportView(data: viewModel.monthlyCommissionData)
                        case .renewalRate:
                            RenewalRateReportView(data: viewModel.renewalRateData)
                        case .followUpConversion:
                            FollowUpConversionReportView(data: viewModel.followUpConversionData)
                        case .custom:
                            CustomReportView()
                        }
                    }
                    .padding()
                }
                
                // Export Button
                Button(action: { showingExportOptions = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export Report")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationTitle("Reports")
            .onAppear {
                viewModel.loadReportData(context: viewContext)
            }
        }
        .actionSheet(isPresented: $showingExportOptions) {
            ActionSheet(
                title: Text("Export Format"),
                buttons: ExportFormat.allCases.map { format in
                    .default(Text(format.rawValue)) {
                        exportFormat = format
                        exportReport()
                    }
                } + [.cancel()]
            )
        }
    }
    
    private func exportReport() {
        // Implement export functionality based on selected format
        switch exportFormat {
        case .csv:
            exportToCSV()
        case .excel:
            exportToExcel()
        case .pdf:
            exportToPDF()
        }
    }
    
    private func exportToCSV() {
        // Generate CSV content
        let csvContent = generateCSVContent()
        saveToDocuments(content: csvContent, filename: "\(selectedReportType.rawValue).csv")
    }
    
    private func exportToExcel() {
        // Generate Excel content (simplified)
        let excelContent = generateExcelContent()
        saveToDocuments(content: excelContent, filename: "\(selectedReportType.rawValue).xlsx")
    }
    
    private func exportToPDF() {
        // Generate PDF content
        let pdfData = generatePDFContent()
        saveToDocuments(data: pdfData, filename: "\(selectedReportType.rawValue).pdf")
    }
    
    private func saveToDocuments(content: String, filename: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            print("File saved to: \(fileURL)")
        } catch {
            print("Error saving file: \(error)")
        }
    }
    
    private func saveToDocuments(data: Data, filename: String) {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsPath.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            print("File saved to: \(fileURL)")
        } catch {
            print("Error saving file: \(error)")
        }
    }
    
    private func generateCSVContent() -> String {
        switch selectedReportType {
        case .clientList:
            return generateClientListCSV()
        case .monthlyCommission:
            return generateMonthlyCommissionCSV()
        case .renewalRate:
            return generateRenewalRateCSV()
        case .followUpConversion:
            return generateFollowUpConversionCSV()
        case .custom:
            return "Custom report CSV content"
        }
    }
    
    private func generateExcelContent() -> String {
        // Simplified Excel content (in production, use a proper Excel library)
        return "Excel content for \(selectedReportType.rawValue)"
    }
    
    private func generatePDFContent() -> Data {
        // Generate PDF content
        let _ = [
            kCGPDFContextCreator: "Insurance Agent CRM",
            kCGPDFContextAuthor: "Insurance Agent",
            kCGPDFContextTitle: selectedReportType.rawValue
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let titleFont = UIFont.boldSystemFont(ofSize: 18)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            
            let title = selectedReportType.rawValue
            let titleRect = CGRect(x: 50, y: 50, width: pageWidth - 100, height: 30)
            title.draw(in: titleRect, withAttributes: [.font: titleFont])
            
            let content = generateReportContent()
            let contentRect = CGRect(x: 50, y: 100, width: pageWidth - 100, height: pageHeight - 150)
            content.draw(in: contentRect, withAttributes: [.font: bodyFont])
        }
    }
    
    private func generateReportContent() -> String {
        switch selectedReportType {
        case .clientList:
            return "Client List Report\n\nTotal Clients: \(viewModel.clientListData.count)\n\n" + viewModel.clientListData.map { client in
                "\(client.firstName) \(client.lastName) - \(client.email ?? "No email")"
            }.joined(separator: "\n")
        case .monthlyCommission:
            return "Monthly Commission Report\n\nTarget: $\(viewModel.monthlyCommissionData.target)\nEarned: $\(viewModel.monthlyCommissionData.earned)\nProgress: \(viewModel.monthlyCommissionData.progress)%"
        case .renewalRate:
            return "Renewal Rate Report\n\nTotal Policies: \(viewModel.renewalRateData.totalPolicies)\nRenewed: \(viewModel.renewalRateData.renewed)\nRate: \(viewModel.renewalRateData.rate)%"
        case .followUpConversion:
            return "Follow-up Conversion Report\n\nTotal Follow-ups: \(viewModel.followUpConversionData.totalFollowUps)\nConverted: \(viewModel.followUpConversionData.converted)\nRate: \(viewModel.followUpConversionData.rate)%"
        case .custom:
            return "Custom Report Content"
        }
    }
    
    private func generateClientListCSV() -> String {
        var csv = "First Name,Last Name,Email,Phone,WhatsApp Opt-in,Created Date\n"
        for client in viewModel.clientListData {
            csv += "\(client.firstName),\(client.lastName),\(client.email ?? ""),\(client.phone),\(client.whatsappOptIn ? "Yes" : "No"),\(client.createdAt.formatted(date: .abbreviated, time: .omitted))\n"
        }
        return csv
    }
    
    private func generateMonthlyCommissionCSV() -> String {
        return "Month,Target,Earned,Progress\n\(Date().formatted(.dateTime.month().year())),\(viewModel.monthlyCommissionData.target),\(viewModel.monthlyCommissionData.earned),\(viewModel.monthlyCommissionData.progress)%"
    }
    
    private func generateRenewalRateCSV() -> String {
        return "Total Policies,Renewed,Rate\n\(viewModel.renewalRateData.totalPolicies),\(viewModel.renewalRateData.renewed),\(viewModel.renewalRateData.rate)%"
    }
    
    private func generateFollowUpConversionCSV() -> String {
        return "Total Follow-ups,Converted,Rate\n\(viewModel.followUpConversionData.totalFollowUps),\(viewModel.followUpConversionData.converted),\(viewModel.followUpConversionData.rate)%"
    }
}

// MARK: - Report Views
struct ClientListReportView: View {
    let data: [ClientReportData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Client Summary")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Clients")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(data.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("WhatsApp Opt-in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(data.filter { $0.whatsappOptIn }.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            if !data.isEmpty {
                List(data.prefix(10)) { client in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(client.firstName) \(client.lastName)")
                                .font(.headline)
                            Text(client.email ?? "No email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if client.whatsappOptIn {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

struct MonthlyCommissionReportView: View {
    let data: MonthlyCommissionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Commission Progress")
                .font(.headline)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Target")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(data.target)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Earned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("$\(data.earned)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
                
                // Progress Bar
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(data.progress)%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    
                    ProgressView(value: Double(data.progress), total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .green))
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct RenewalRateReportView: View {
    let data: RenewalRateData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Renewal Performance")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Policies")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(data.totalPolicies)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("Renewal Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(data.rate)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.rate >= 80 ? .green : .orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Renewed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(data.renewed)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct FollowUpConversionReportView: View {
    let data: FollowUpConversionData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow-up Effectiveness")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Follow-ups")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(data.totalFollowUps)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .center) {
                    Text("Conversion Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(data.rate)%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(data.rate >= 20 ? .green : .orange)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Converted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(data.converted)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct CustomReportView: View {
    @State private var selectedFields: [String] = []
    @State private var dateRange = DateRange.lastMonth
    @State private var filters: [String: String] = [:]
    
    enum DateRange: String, CaseIterable {
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastQuarter = "Last Quarter"
        case lastYear = "Last Year"
        case custom = "Custom Range"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Report Builder")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Date Range")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Date Range", selection: $dateRange) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Fields to Include")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(["Client Name", "Email", "Phone", "Commission", "Status", "Date"], id: \.self) { field in
                        Button(field) {
                            if selectedFields.contains(field) {
                                selectedFields.removeAll { $0 == field }
                            } else {
                                selectedFields.append(field)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedFields.contains(field) ? Color.blue : Color(.systemGray6))
                        .foregroundColor(selectedFields.contains(field) ? .white : .primary)
                        .cornerRadius(8)
                    }
                }
            }
            
            if selectedFields.isEmpty {
                Text("Select at least one field to generate the report")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Data Models
struct ClientReportData: Identifiable {
    let id = UUID()
    let firstName: String
    let lastName: String
    let email: String?
    let phone: String
    let whatsappOptIn: Bool
    let createdAt: Date
}

struct MonthlyCommissionData {
    let target: String
    let earned: String
    let progress: Int
}

struct RenewalRateData {
    let totalPolicies: Int
    let renewed: Int
    let rate: Int
}

struct FollowUpConversionData {
    let totalFollowUps: Int
    let converted: Int
    let rate: Int
}

// MARK: - View Model
class ReportsViewModel: ObservableObject {
    @Published var clientListData: [ClientReportData] = []
    @Published var monthlyCommissionData = MonthlyCommissionData(target: "5000", earned: "3250", progress: 65)
    @Published var renewalRateData = RenewalRateData(totalPolicies: 150, renewed: 120, rate: 80)
    @Published var followUpConversionData = FollowUpConversionData(totalFollowUps: 50, converted: 12, rate: 24)
    
    func loadReportData(context: NSManagedObjectContext) {
        loadClientListData(context: context)
        // Other data loading would be implemented here
    }
    
    private func loadClientListData(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Client.createdAt, ascending: false)]
        
        do {
            let clients = try context.fetch(request)
            clientListData = clients.map { client in
                ClientReportData(
                    firstName: client.firstName ?? "",
                    lastName: client.lastName ?? "",
                    email: client.email,
                    phone: client.phone ?? "",
                    whatsappOptIn: client.whatsappOptIn,
                    createdAt: client.createdAt ?? Date()
                )
            }
        } catch {
            print("Error loading client data: \(error)")
        }
    }
}

#Preview {
    ReportsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}



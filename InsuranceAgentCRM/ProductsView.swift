import SwiftUI
import CoreData

struct ProductsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var viewModel = ProductsViewModel()
    @State private var showingAddProduct = false
    @State private var selectedProduct: Product?
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Products List
                if filteredProducts.isEmpty {
                    EmptyStateView(
                        icon: "shippingbox.fill",
                        title: "No Products",
                        subtitle: "Add your first product to get started"
                    )
                } else {
                    List {
                        ForEach(filteredProducts) { product in
                            ProductRowView(product: product) {
                                selectedProduct = product
                            }
                        }
                        .onDelete(perform: deleteProducts)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Products")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddProduct = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView()
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $selectedProduct) { product in
                ProductDetailView(product: product)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onAppear {
            // Fetch from Firebase first, then load local products
            firebaseManager.fetchAllData(context: viewContext)
            viewModel.loadProducts(context: viewContext)
        }
    }
    
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return viewModel.products
        } else {
            return viewModel.products.filter { product in
                product.name?.localizedCaseInsensitiveContains(searchText) == true ||
                product.code?.localizedCaseInsensitiveContains(searchText) == true ||
                product.productType?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func deleteProducts(offsets: IndexSet) {
        withAnimation {
            var deletedProducts: [Product] = []
            for index in offsets {
                let product = filteredProducts[index]
                deletedProducts.append(product)
                viewContext.delete(product)
            }
            
            do {
                try viewContext.save()
                
                // Sync deleted products to Firebase
                for product in deletedProducts {
                    firebaseManager.syncStandaloneProduct(product)
                }
                
                viewModel.loadProducts(context: viewContext)
            } catch {
                print("Error deleting product: \(error)")
            }
        }
    }
}

struct ProductRowView: View {
    let product: Product
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Product Icon
                Circle()
                    .fill(productTypeColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: productTypeIcon)
                            .font(.title2)
                            .foregroundColor(productTypeColor)
                    )
                
                // Product Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name ?? "Untitled Product")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(product.code ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(product.productType ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Price
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Base Premium")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatCurrency(product.basePremium?.decimalValue ?? 0))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var productTypeColor: Color {
        switch product.productType?.lowercased() {
        case "life":
            return .blue
        case "health":
            return .green
        case "auto":
            return .orange
        case "home":
            return .purple
        default:
            return .gray
        }
    }
    
    private var productTypeIcon: String {
        switch product.productType?.lowercased() {
        case "life":
            return "heart.fill"
        case "health":
            return "cross.fill"
        case "auto":
            return "car.fill"
        case "home":
            return "house.fill"
        default:
            return "shippingbox.fill"
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

struct AddProductView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    @State private var code = ""
    @State private var name = ""
    @State private var productType = "Life"
    @State private var basePremium: Decimal = 0
    @State private var description = ""
    @State private var riders: [String] = []
    @State private var newRider = ""
    
    private let productTypes = ["Life", "Health", "Auto", "Home", "Business", "Travel"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Product Information") {
                    TextField("Product Code", text: $code)
                    TextField("Product Name", text: $name)
                    
                    Picker("Product Type", selection: $productType) {
                        ForEach(productTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("Base Premium")
                        Spacer()
                        TextField("Amount", value: $basePremium, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Description") {
                    TextField("Product Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Riders") {
                    ForEach(riders, id: \.self) { rider in
                        HStack {
                            Text(rider)
                            Spacer()
                            Button("Remove") {
                                riders.removeAll { $0 == rider }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add rider", text: $newRider)
                        Button("Add") {
                            if !newRider.isEmpty {
                                riders.append(newRider)
                                newRider = ""
                            }
                        }
                        .disabled(newRider.isEmpty)
                    }
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProduct()
                    }
                    .disabled(code.isEmpty || name.isEmpty)
                }
            }
        }
    }
    
    private func saveProduct() {
        let product = Product(context: viewContext)
        product.id = UUID()
        product.code = code
        product.name = name
        product.productType = productType
        product.basePremium = NSDecimalNumber(decimal: basePremium)
        product.productDescription = description.isEmpty ? nil : description
        product.riders = riders.isEmpty ? nil : riders as NSObject
        product.createdAt = Date()
        product.updatedAt = Date()
        
        do {
            try viewContext.save()
            
            // Sync product to Firebase
            firebaseManager.syncStandaloneProduct(product)
            dismiss()
        } catch {
            print("Error saving product: \(error)")
        }
    }
}

struct ProductDetailView: View {
    let product: Product
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditProduct = false
    @State private var showingQuoteBuilder = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Circle()
                            .fill(productTypeColor.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: productTypeIcon)
                                    .font(.title)
                                    .foregroundColor(productTypeColor)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(product.name ?? "Untitled Product")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(product.code ?? "")
                                .foregroundColor(.secondary)
                            
                            Text(product.productType ?? "")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(productTypeColor.opacity(0.2))
                                .foregroundColor(productTypeColor)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Quick Actions
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ActionButton(
                            icon: "doc.text.fill",
                            title: "Create Quote",
                            color: .blue
                        ) {
                            showingQuoteBuilder = true
                        }
                        
                        ActionButton(
                            icon: "list.bullet",
                            title: "View Quotes",
                            color: .green
                        ) {
                            // Implement view quotes functionality
                        }
                    }
                    
                    // Product Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Product Details")
                            .font(.headline)
                        
                        InfoRow(label: "Base Premium", value: formatCurrency(product.basePremium?.decimalValue ?? 0))
                        
                        if let description = product.productDescription {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(description)
                                    .font(.subheadline)
                            }
                        }
                        
                        if let riders = product.riders as? [String], !riders.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Available Riders")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                LazyVGrid(columns: [
                                    GridItem(.adaptive(minimum: 100))
                                ], spacing: 8) {
                                    ForEach(riders, id: \.self) { rider in
                                        Text(rider)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Product Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProduct = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProduct) {
            EditProductView(product: product)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showingQuoteBuilder) {
            QuoteBuilderView(product: product)
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var productTypeColor: Color {
        switch product.productType?.lowercased() {
        case "life":
            return .blue
        case "health":
            return .green
        case "auto":
            return .orange
        case "home":
            return .purple
        default:
            return .gray
        }
    }
    
    private var productTypeIcon: String {
        switch product.productType?.lowercased() {
        case "life":
            return "heart.fill"
        case "health":
            return "cross.fill"
        case "auto":
            return "car.fill"
        case "home":
            return "house.fill"
        default:
            return "shippingbox.fill"
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

struct EditProductView: View {
    let product: Product
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    @State private var code: String
    @State private var name: String
    @State private var productType: String
    @State private var basePremium: Decimal
    @State private var description: String
    @State private var riders: [String]
    @State private var newRider = ""
    
    private let productTypes = ["Life", "Health", "Auto", "Home", "Business", "Travel"]
    
    init(product: Product) {
        self.product = product
        _code = State(initialValue: product.code ?? "")
        _name = State(initialValue: product.name ?? "")
        _productType = State(initialValue: product.productType ?? "Life")
        _basePremium = State(initialValue: product.basePremium?.decimalValue ?? 0)
        _description = State(initialValue: product.productDescription ?? "")
        _riders = State(initialValue: (product.riders as? [String]) ?? [])
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Product Information") {
                    TextField("Product Code", text: $code)
                    TextField("Product Name", text: $name)
                    
                    Picker("Product Type", selection: $productType) {
                        ForEach(productTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    HStack {
                        Text("Base Premium")
                        Spacer()
                        TextField("Amount", value: $basePremium, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Description") {
                    TextField("Product Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Riders") {
                    ForEach(riders, id: \.self) { rider in
                        HStack {
                            Text(rider)
                            Spacer()
                            Button("Remove") {
                                riders.removeAll { $0 == rider }
                            }
                            .foregroundColor(.red)
                        }
                    }
                    
                    HStack {
                        TextField("Add rider", text: $newRider)
                        Button("Add") {
                            if !newRider.isEmpty {
                                riders.append(newRider)
                                newRider = ""
                            }
                        }
                        .disabled(newRider.isEmpty)
                    }
                }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(code.isEmpty || name.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        product.code = code
        product.name = name
        product.productType = productType
        product.basePremium = NSDecimalNumber(decimal: basePremium)
        product.productDescription = description.isEmpty ? nil : description
        product.riders = riders.isEmpty ? nil : riders as NSObject
        product.updatedAt = Date()
        
        do {
            try viewContext.save()
            
            // Sync product to Firebase
            firebaseManager.syncStandaloneProduct(product)
            dismiss()
        } catch {
            print("Error saving product: \(error)")
        }
    }
}

struct QuoteBuilderView: View {
    let product: Product
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    @State private var selectedClient: Client?
    @State private var coverageAmount: Decimal = 0
    @State private var selectedRiders: [String] = []
    @State private var discount: Decimal = 0
    @State private var finalPremium: Decimal = 0
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Client.lastName, ascending: true),
            NSSortDescriptor(keyPath: \Client.firstName, ascending: true)
        ]
    ) private var clients: FetchedResults<Client>
    
    var body: some View {
        NavigationView {
            Form {
                Section("Client Selection") {
                    Picker("Client", selection: $selectedClient) {
                        Text("Select Client").tag(nil as Client?)
                        ForEach(clients, id: \.self) { client in
                            Text("\(client.firstName ?? "") \(client.lastName ?? "")").tag(client as Client?)
                        }
                    }
                }
                
                Section("Coverage Details") {
                    HStack {
                        Text("Coverage Amount")
                        Spacer()
                        TextField("Amount", value: $coverageAmount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let riders = product.riders as? [String], !riders.isEmpty {
                    Section("Riders") {
                        ForEach(riders, id: \.self) { rider in
                            HStack {
                                Text(rider)
                                Spacer()
                                Button(selectedRiders.contains(rider) ? "Remove" : "Add") {
                                    if selectedRiders.contains(rider) {
                                        selectedRiders.removeAll { $0 == rider }
                                    } else {
                                        selectedRiders.append(rider)
                                    }
                                }
                                .foregroundColor(selectedRiders.contains(rider) ? .red : .blue)
                            }
                        }
                    }
                }
                
                Section("Discount") {
                    HStack {
                        Text("Discount Amount")
                        Spacer()
                        TextField("Amount", value: $discount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Quote Summary") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Base Premium:")
                            Spacer()
                            Text(formatCurrency(product.basePremium?.decimalValue ?? 0))
                        }
                        
                        if !selectedRiders.isEmpty {
                            HStack {
                                Text("Riders:")
                                Spacer()
                                Text("+$\(selectedRiders.count * 50)") // Simplified rider pricing
                            }
                        }
                        
                        if discount > 0 {
                            HStack {
                                Text("Discount:")
                                Spacer()
                                Text("-\(formatCurrency(discount))")
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Final Premium:")
                                .fontWeight(.bold)
                            Spacer()
                            Text(formatCurrency(calculateFinalPremium()))
                                .fontWeight(.bold)
                        }
                    }
                }
            }
            .navigationTitle("Create Quote")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save Quote") {
                        saveQuote()
                    }
                    .disabled(selectedClient == nil || coverageAmount <= 0)
                }
            }
        }
        .onChange(of: coverageAmount) { _, _ in updateFinalPremium() }
        .onChange(of: selectedRiders) { _, _ in updateFinalPremium() }
        .onChange(of: discount) { _, _ in updateFinalPremium() }
    }
    
    private func calculateFinalPremium() -> Decimal {
        var premium = product.basePremium?.decimalValue ?? 0
        
        // Add rider costs (simplified)
        premium += Decimal(selectedRiders.count * 50)
        
        // Apply discount
        premium -= discount
        
        return max(premium, 0)
    }
    
    private func updateFinalPremium() {
        finalPremium = calculateFinalPremium()
    }
    
    private func saveQuote() {
        let quote = Quote(context: viewContext)
        quote.id = UUID()
        quote.client = selectedClient
        quote.product = product
        quote.coverageAmount = NSDecimalNumber(decimal: coverageAmount)
        quote.selectedRiders = selectedRiders.isEmpty ? nil : selectedRiders as NSObject
        quote.discount = NSDecimalNumber(decimal: discount)
        quote.finalPremium = NSDecimalNumber(decimal: finalPremium)
        quote.status = "draft"
        quote.createdAt = Date()
        quote.updatedAt = Date()
        
        do {
            try viewContext.save()
            
            // Sync product to Firebase
            firebaseManager.syncStandaloneProduct(product)
            dismiss()
        } catch {
            print("Error saving quote: \(error)")
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

class ProductsViewModel: ObservableObject {
    @Published var products: [Product] = []
    
    func loadProducts(context: NSManagedObjectContext) {
        let request: NSFetchRequest<Product> = Product.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Product.name, ascending: true)]
        
        do {
            products = try context.fetch(request)
        } catch {
            print("Error loading products: \(error)")
        }
    }
}

// MARK: - Supporting Views
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    ProductsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


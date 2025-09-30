import SwiftUI

// MARK: - Common Form Components
struct FormTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    
    init(title: String, text: Binding<String>, placeholder: String = "", keyboardType: UIKeyboardType = .default) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        TextField(placeholder.isEmpty ? title : placeholder, text: $text)
            .keyboardType(keyboardType)
    }
}

struct FormPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    @State private var showingPicker = false
    
    var body: some View {
        // Use Menu for iOS 14+ for better mobile experience
        if #available(iOS 14.0, *) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selection = option
                    }) {
                        HStack {
                            Text(option)
                            if selection == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text(title)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(selection)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        } else {
            // Fallback to sheet for iOS 13
            Button(action: {
                showingPicker = true
            }) {
                HStack {
                    Text(title)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(selection)
                        .foregroundColor(.secondary)
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingPicker) {
                NavigationView {
                    List {
                        ForEach(options, id: \.self) { option in
                            Button(action: {
                                selection = option
                                showingPicker = false
                            }) {
                                HStack {
                                    Text(option)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selection == option {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingPicker = false
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FormTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let lineLimit: ClosedRange<Int>
    
    init(title: String, text: Binding<String>, placeholder: String = "", lineLimit: ClosedRange<Int> = 3...6) {
        self.title = title
        self._text = text
        self.placeholder = placeholder
        self.lineLimit = lineLimit
    }
    
    var body: some View {
        TextField(placeholder.isEmpty ? title : placeholder, text: $text, axis: .vertical)
            .lineLimit(lineLimit)
    }
}

// MARK: - Common Card Components
struct CardTitle: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.medium)
    }
}

struct CardAmount: View {
    let amount: Double
    let color: Color
    
    var body: some View {
        Text("$\(amount, specifier: "%.2f")")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
    }
}

struct CardDescription: View {
    let description: String?
    
    var body: some View {
        if let description = description, !description.isEmpty {
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
}

struct CardStatusBadge: View {
    let status: String
    let color: Color
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .cornerRadius(4)
    }
}

// MARK: - Common Button Components
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.UI.mobileButtonHeight)
                .background(AppConstants.Colors.primary)
                .cornerRadius(AppConstants.UI.mobileCornerRadius)
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppConstants.Colors.primary)
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.UI.mobileButtonHeight)
                .background(AppConstants.Colors.primary.opacity(0.1))
                .cornerRadius(AppConstants.UI.mobileCornerRadius)
        }
    }
}

struct DestructiveButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: AppConstants.UI.mobileButtonHeight)
                .background(AppConstants.Colors.error)
                .cornerRadius(AppConstants.UI.mobileCornerRadius)
        }
    }
}

// MARK: - Common Loading Components
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppConstants.Colors.primary))
                .scaleEffect(1.2)
            
            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3))
    }
}

// MARK: - EmptyStateView (moved to avoid conflicts)
// EmptyStateView is already defined in EmptyStateView.swift

// MARK: - Common Section Components
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(title: String, subtitle: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.caption)
                        .foregroundColor(AppConstants.Colors.primary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Common Badge Components (moved to avoid conflicts)
// StatusBadge and TagBadge are already defined in ClientsContentView.swift

// MARK: - Common List Components
struct ListRow: View {
    let title: String
    let subtitle: String?
    let trailing: AnyView?
    let action: (() -> Void)?
    
    init(title: String, subtitle: String? = nil, trailing: AnyView? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.action = action
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let trailing = trailing {
                trailing
            }
            
            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

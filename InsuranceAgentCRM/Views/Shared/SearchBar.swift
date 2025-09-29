import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var placeholder: String
    var onSearchButtonClicked: (() -> Void)?
    var onCancelButtonClicked: (() -> Void)?
    
    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        onSearchButtonClicked: (() -> Void)? = nil,
        onCancelButtonClicked: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onCancelButtonClicked = onCancelButtonClicked
    }
    
    var body: some View {
        HStack(spacing: DeviceInfo.mobileSpacing) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: DeviceInfo.isIPhone ? 16 : 14))
            
            // Text Field
            TextField(placeholder, text: $text)
                .font(.system(size: DeviceInfo.isIPhone ? 16 : 15))
                .focused($isFocused)
                .onSubmit {
                    onSearchButtonClicked?()
                }
                .onChange(of: isFocused) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing = newValue
                    }
                }
            
            // Clear Button
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                        isFocused = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: DeviceInfo.isIPhone ? 16 : 14))
                }
                .mobileTouchTarget()
                .transition(.scale.combined(with: .opacity))
            }
            
            // Cancel Button (shown when editing)
            if isEditing {
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                        isFocused = false
                    }
                    onCancelButtonClicked?()
                }
                .font(.system(size: DeviceInfo.isIPhone ? 16 : 14, weight: .medium))
                .foregroundColor(.blue)
                .mobileTouchTarget()
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, DeviceInfo.isIPhone ? 16 : 12)
        .padding(.vertical, DeviceInfo.isIPhone ? 12 : 10)
        .background(Color(.systemGray6))
        .cornerRadius(DeviceInfo.mobileCornerRadius)
        .keyboardAwareWithDismissal()
    }
}

// MARK: - Advanced Search Bar with Keyboard Handling
struct AdvancedSearchBar: View {
    @Binding var text: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    @StateObject private var keyboardManager = KeyboardManager()
    
    var placeholder: String
    var onSearchButtonClicked: (() -> Void)?
    var onCancelButtonClicked: (() -> Void)?
    var showCancelButton: Bool
    
    init(
        text: Binding<String>,
        placeholder: String = "Search...",
        showCancelButton: Bool = true,
        onSearchButtonClicked: (() -> Void)? = nil,
        onCancelButtonClicked: (() -> Void)? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.showCancelButton = showCancelButton
        self.onSearchButtonClicked = onSearchButtonClicked
        self.onCancelButtonClicked = onCancelButtonClicked
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DeviceInfo.mobileSpacing) {
                // Search Icon
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: DeviceInfo.isIPhone ? 16 : 14))
                
                // Text Field
                TextField(placeholder, text: $text)
                    .font(.system(size: DeviceInfo.isIPhone ? 16 : 15))
                    .focused($isFocused)
                    .onSubmit {
                        onSearchButtonClicked?()
                    }
                    .onChange(of: isFocused) { _, newValue in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing = newValue
                        }
                    }
                
                // Clear Button
                if !text.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            text = ""
                            isFocused = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: DeviceInfo.isIPhone ? 16 : 14))
                    }
                    .mobileTouchTarget()
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Cancel Button (shown when editing and enabled)
                if isEditing && showCancelButton {
                    Button("Cancel") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            text = ""
                            isFocused = false
                        }
                        onCancelButtonClicked?()
                    }
                    .font(.system(size: DeviceInfo.isIPhone ? 16 : 14, weight: .medium))
                    .foregroundColor(.blue)
                    .mobileTouchTarget()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .padding(.horizontal, DeviceInfo.isIPhone ? 16 : 12)
            .padding(.vertical, DeviceInfo.isIPhone ? 12 : 10)
            .background(Color(.systemGray6))
            .cornerRadius(DeviceInfo.mobileCornerRadius)
            
            // Keyboard indicator (optional)
            if keyboardManager.isKeyboardVisible && isFocused {
                HStack {
                    Text("Tap outside to dismiss keyboard")
                        .font(.system(size: DeviceInfo.isIPhone ? 12 : 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                    .font(.system(size: DeviceInfo.isIPhone ? 12 : 11, weight: .medium))
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, DeviceInfo.isIPhone ? 16 : 12)
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .keyboardAwareWithDismissal()
    }
}

// MARK: - Compact Search Bar for Navigation Bars
struct CompactSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var placeholder: String
    
    init(text: Binding<String>, placeholder: String = "Search...") {
        self._text = text
        self.placeholder = placeholder
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: DeviceInfo.isIPhone ? 14 : 12))
            
            TextField(placeholder, text: $text)
                .font(.system(size: DeviceInfo.isIPhone ? 15 : 14))
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: DeviceInfo.isIPhone ? 14 : 12))
                }
                .mobileTouchTarget()
            }
        }
        .padding(.horizontal, DeviceInfo.isIPhone ? 12 : 10)
        .padding(.vertical, DeviceInfo.isIPhone ? 8 : 6)
        .background(Color(.systemGray6))
        .cornerRadius(DeviceInfo.mobileCornerRadius)
        .keyboardAwareWithDismissal()
    }
}

#Preview {
    VStack(spacing: 20) {
        SearchBar(text: .constant(""))
        AdvancedSearchBar(text: .constant(""))
        CompactSearchBar(text: .constant(""))
    }
    .padding()
}
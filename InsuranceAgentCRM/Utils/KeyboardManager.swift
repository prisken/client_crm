import SwiftUI
import Combine

// MARK: - Custom Notification Names
extension Notification.Name {
    static let tagInputFocused = Notification.Name("tagInputFocused")
    static let clientDataChanged = Notification.Name("clientDataChanged")
}

// MARK: - Keyboard Manager
class KeyboardManager: ObservableObject {
    @Published var isKeyboardVisible = false
    @Published var keyboardHeight: CGFloat = 0
    @Published var keyboardAnimationDuration: Double = 0.25
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupKeyboardObservers()
    }
    
    private func setupKeyboardObservers() {
        // Keyboard will show
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardWillShow(notification)
            }
            .store(in: &cancellables)
        
        // Keyboard will hide
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] notification in
                self?.handleKeyboardWillHide(notification)
            }
            .store(in: &cancellables)
    }
    
    private func handleKeyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        withAnimation(.easeOut(duration: animationDuration)) {
            self.isKeyboardVisible = true
            self.keyboardHeight = keyboardFrame.height
            self.keyboardAnimationDuration = animationDuration
        }
    }
    
    private func handleKeyboardWillHide(_ notification: Notification) {
        guard let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        withAnimation(.easeOut(duration: animationDuration)) {
            self.isKeyboardVisible = false
            self.keyboardHeight = 0
            self.keyboardAnimationDuration = animationDuration
        }
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Keyboard Aware View Modifier
struct KeyboardAwareModifier: ViewModifier {
    @ObservedObject var keyboardManager: KeyboardManager
    let extraPadding: CGFloat
    
    init(extraPadding: CGFloat = 0) {
        self.keyboardManager = KeyboardManager()
        self.extraPadding = extraPadding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardManager.isKeyboardVisible ? keyboardManager.keyboardHeight + extraPadding : 0)
            .animation(.easeOut(duration: keyboardManager.keyboardAnimationDuration), value: keyboardManager.keyboardHeight)
    }
}

// MARK: - Enhanced Mobile Keyboard Aware Modifier
struct MobileKeyboardAwareModifier: ViewModifier {
    @ObservedObject var keyboardManager: KeyboardManager
    let extraPadding: CGFloat
    let dismissOnTap: Bool
    
    init(extraPadding: CGFloat = 0, dismissOnTap: Bool = true) {
        self.keyboardManager = KeyboardManager()
        self.extraPadding = extraPadding
        self.dismissOnTap = dismissOnTap
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardManager.isKeyboardVisible ? keyboardManager.keyboardHeight + extraPadding : 0)
            .animation(.easeOut(duration: keyboardManager.keyboardAnimationDuration), value: keyboardManager.keyboardHeight)
            .onTapGesture {
                if dismissOnTap {
                    keyboardManager.dismissKeyboard()
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func keyboardAware(extraPadding: CGFloat = 0) -> some View {
        self.modifier(KeyboardAwareModifier(extraPadding: extraPadding))
    }
    
    func mobileKeyboardAware(extraPadding: CGFloat = 0, dismissOnTap: Bool = true) -> some View {
        self.modifier(MobileKeyboardAwareModifier(extraPadding: extraPadding, dismissOnTap: dismissOnTap))
    }
    
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    func keyboardAwareWithDismissal(extraPadding: CGFloat = 0) -> some View {
        self.keyboardAware(extraPadding: extraPadding)
    }
    
    // MARK: - Mobile-Specific Keyboard Handling
    func mobileKeyboardAware(
        extraPadding: CGFloat = 20,
        dismissOnTap: Bool = true,
        scrollToActiveField: Bool = true
    ) -> some View {
        self.modifier(MobileKeyboardAwareModifier(extraPadding: extraPadding, dismissOnTap: dismissOnTap))
    }
    
    // MARK: - Enhanced Mobile Keyboard Handling
    func enhancedMobileKeyboardAware(
        extraPadding: CGFloat = 20,
        dismissOnTap: Bool = true,
        scrollToActiveField: Bool = true
    ) -> some View {
        MobileKeyboardAwareView(
            extraPadding: extraPadding,
            dismissOnTap: dismissOnTap,
            scrollToActiveField: scrollToActiveField
        ) {
            self
        }
    }
    
    // MARK: - Tag Input Keyboard Handling
    func tagInputKeyboardAware(extraPadding: CGFloat = 50) -> some View {
        TagInputKeyboardHandler(extraPadding: extraPadding) {
            self
        }
    }
    
    // MARK: - Enhanced Tag Input Keyboard Handling
    func enhancedTagInputKeyboardAware(extraPadding: CGFloat = 60) -> some View {
        EnhancedTagInputKeyboardHandler(extraPadding: extraPadding) {
            self
        }
    }
}

// MARK: - Keyboard Safe Area
struct KeyboardSafeArea: View {
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        content
            .keyboardAwareWithDismissal()
    }
}

// MARK: - ScrollView with Keyboard Handling
struct KeyboardAwareScrollView<Content: View>: View {
    let content: Content
    @StateObject private var keyboardManager = KeyboardManager()
    let extraPadding: CGFloat
    let dismissOnTap: Bool
    
    init(extraPadding: CGFloat = 16, dismissOnTap: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.extraPadding = extraPadding
        self.dismissOnTap = dismissOnTap
    }
    
    var body: some View {
        ScrollView {
            content
                .padding(.bottom, keyboardManager.isKeyboardVisible ? keyboardManager.keyboardHeight + extraPadding : 0)
        }
        .animation(.easeOut(duration: keyboardManager.keyboardAnimationDuration), value: keyboardManager.keyboardHeight)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if dismissOnTap {
                        keyboardManager.dismissKeyboard()
                    }
                }
        )
    }
}

// MARK: - Form with Keyboard Handling
struct KeyboardAwareForm<Content: View>: View {
    let content: Content
    @StateObject private var keyboardManager = KeyboardManager()
    let extraPadding: CGFloat
    let dismissOnTap: Bool
    
    init(extraPadding: CGFloat = 20, dismissOnTap: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.extraPadding = extraPadding
        self.dismissOnTap = dismissOnTap
    }
    
    var body: some View {
        Form {
            content
        }
        .keyboardAware(extraPadding: extraPadding)
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if dismissOnTap {
                        keyboardManager.dismissKeyboard()
                    }
                }
        )
    }
}

// MARK: - Navigation View with Keyboard Handling
struct KeyboardAwareNavigationView<Content: View>: View {
    let content: Content
    @StateObject private var keyboardManager = KeyboardManager()
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        NavigationView {
            content
        }
    }
}

// MARK: - Sheet with Keyboard Handling
struct KeyboardAwareSheet<Content: View>: View {
    let content: Content
    @StateObject private var keyboardManager = KeyboardManager()
    let extraPadding: CGFloat
    
    init(extraPadding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.extraPadding = extraPadding
    }
    
    var body: some View {
        content
            .keyboardAwareWithDismissal(extraPadding: extraPadding)
    }
}

// MARK: - Mobile-Optimized Keyboard Handling
struct MobileKeyboardAwareView<Content: View>: View {
    let content: Content
    @StateObject private var keyboardManager = KeyboardManager()
    let extraPadding: CGFloat
    let dismissOnTap: Bool
    let scrollToActiveField: Bool
    
    init(
        extraPadding: CGFloat = 20,
        dismissOnTap: Bool = true,
        scrollToActiveField: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.extraPadding = extraPadding
        self.dismissOnTap = dismissOnTap
        self.scrollToActiveField = scrollToActiveField
    }
    
    var body: some View {
        content
            .padding(.bottom, keyboardManager.isKeyboardVisible ? keyboardManager.keyboardHeight + extraPadding : 0)
            .animation(.easeOut(duration: keyboardManager.keyboardAnimationDuration), value: keyboardManager.keyboardHeight)
            .onTapGesture {
                if dismissOnTap {
                    keyboardManager.dismissKeyboard()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                if scrollToActiveField {
                    // Scroll to active field when keyboard appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        // This will be handled by the ScrollViewReader in the parent view
                    }
                }
            }
    }
}

// MARK: - Tag Input Keyboard Handler
struct TagInputKeyboardHandler<Content: View>: View {
    let content: Content
    @StateObject private var keyboardManager = KeyboardManager()
    let extraPadding: CGFloat
    
    init(extraPadding: CGFloat = 50, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.extraPadding = extraPadding
    }
    
    var body: some View {
        content
            .padding(.bottom, keyboardManager.isKeyboardVisible ? keyboardManager.keyboardHeight + extraPadding : 0)
            .animation(.easeOut(duration: keyboardManager.keyboardAnimationDuration), value: keyboardManager.keyboardHeight)
            .onTapGesture {
                keyboardManager.dismissKeyboard()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                // Ensure the tag input is visible when keyboard appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    // Force scroll to make the input visible
                    withAnimation(.easeOut(duration: 0.3)) {
                        // This will trigger a scroll to make the input visible
                    }
                }
            }
    }
}

// MARK: - Enhanced Tag Input Keyboard Handler with ScrollViewReader
struct EnhancedTagInputKeyboardHandler<Content: View>: View {
    let content: Content
    @StateObject private var keyboardManager = KeyboardManager()
    let extraPadding: CGFloat
    
    init(extraPadding: CGFloat = 60, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.extraPadding = extraPadding
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            content
                .padding(.bottom, keyboardManager.isKeyboardVisible ? keyboardManager.keyboardHeight + extraPadding : 0)
                .animation(.easeOut(duration: keyboardManager.keyboardAnimationDuration), value: keyboardManager.keyboardHeight)
                .onTapGesture {
                    keyboardManager.dismissKeyboard()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    // Scroll to make the input visible when keyboard appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            // Scroll to the tag input area
                            proxy.scrollTo("tagInputArea", anchor: .center)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .tagInputFocused)) { _ in
                    // Handle tag input focus specifically
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("tagInputArea", anchor: .center)
                        }
                    }
                }
        }
    }
}

// MARK: - Keyboard Height Environment Key
struct KeyboardHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    var keyboardHeight: CGFloat {
        get { self[KeyboardHeightKey.self] }
        set { self[KeyboardHeightKey.self] = newValue }
    }
}

// MARK: - Keyboard Visibility Environment Key
struct KeyboardVisibilityKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isKeyboardVisible: Bool {
        get { self[KeyboardVisibilityKey.self] }
        set { self[KeyboardVisibilityKey.self] = newValue }
    }
}

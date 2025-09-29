import SwiftUI
import Combine

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

// MARK: - View Extensions
extension View {
    func keyboardAware(extraPadding: CGFloat = 0) -> some View {
        self.modifier(KeyboardAwareModifier(extraPadding: extraPadding))
    }
    
    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    func keyboardAwareWithDismissal(extraPadding: CGFloat = 0) -> some View {
        self.keyboardAware(extraPadding: extraPadding)
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
    
    init(extraPadding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.extraPadding = extraPadding
    }
    
    var body: some View {
        ScrollView {
            content
                .padding(.bottom, keyboardManager.isKeyboardVisible ? keyboardManager.keyboardHeight + extraPadding : 0)
        }
        .animation(.easeOut(duration: keyboardManager.keyboardAnimationDuration), value: keyboardManager.keyboardHeight)
    }
}

// MARK: - Form with Keyboard Handling
struct KeyboardAwareForm<Content: View>: View {
    let content: Content
    @StateObject private var keyboardManager = KeyboardManager()
    let extraPadding: CGFloat
    
    init(extraPadding: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.extraPadding = extraPadding
    }
    
    var body: some View {
        Form {
            content
        }
        .keyboardAware(extraPadding: extraPadding)
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

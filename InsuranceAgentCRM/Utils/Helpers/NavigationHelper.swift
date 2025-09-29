import SwiftUI

// MARK: - Navigation Helper
class NavigationHelper: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var selectedClient: Client?
    @Published var showingAddClient = false
    @Published var showingBulkAddClients = false
    @Published var showingSettings = false
    
    // MARK: - Navigation Actions
    func navigateToClient(_ client: Client) {
        selectedClient = client
    }
    
    func showAddClient() {
        showingAddClient = true
    }
    
    func showBulkAddClients() {
        showingBulkAddClients = true
    }
    
    func showSettings() {
        showingSettings = true
    }
    
    func dismissAll() {
        showingAddClient = false
        showingBulkAddClients = false
        showingSettings = false
        selectedClient = nil
    }
}

// MARK: - Navigation Constants
struct NavigationConstants {
    static let tabBarHeight: CGFloat = 49
    static let navigationBarHeight: CGFloat = 44
    static let statusBarHeight: CGFloat = 44
    
    enum Tab: Int, CaseIterable {
        case dashboard = 0
        case clients = 1
        case tasks = 2
        case products = 3
        case reports = 4
        
        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .clients: return "Clients"
            case .tasks: return "Tasks"
            case .products: return "Products"
            case .reports: return "Reports"
            }
        }
        
        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .clients: return "person.2.fill"
            case .tasks: return "checklist"
            case .products: return "shoppingbag.fill"
            case .reports: return "chart.bar.fill"
            }
        }
    }
}

// MARK: - Navigation View Modifier
struct NavigationModifier: ViewModifier {
    @ObservedObject var navigationHelper: NavigationHelper
    
    func body(content: Content) -> some View {
        content
            .environmentObject(navigationHelper)
    }
}

// MARK: - View Extension for Navigation
extension View {
    func navigationHelper(_ helper: NavigationHelper) -> some View {
        self.modifier(NavigationModifier(navigationHelper: helper))
    }
}

// MARK: - Sheet Presentation Helper
struct SheetPresentationHelper {
    @Binding var isPresented: Bool
    let content: () -> AnyView
    
    init<Content: View>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) {
        self._isPresented = isPresented
        self.content = { AnyView(content()) }
    }
}

// MARK: - Navigation Coordinator
class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    @Published var selectedTab: Int = 0
    
    func navigateToClient(_ client: Client) {
        path.append(client)
    }
    
    func navigateToTask(_ task: ClientTask) {
        path.append(task)
    }
    
    func navigateToProduct(_ product: ClientProduct) {
        path.append(product)
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func navigateToRoot() {
        path = NavigationPath()
    }
}

// MARK: - Deep Link Handler
struct DeepLinkHandler {
    static func handle(_ url: URL) -> NavigationPath {
        let path = NavigationPath()
        
        // Parse URL and create navigation path
        // This would be implemented based on your app's deep linking requirements
        
        return path
    }
}

// MARK: - Navigation State Manager
class NavigationStateManager: ObservableObject {
    @Published var currentView: String = "Dashboard"
    @Published var navigationHistory: [String] = []
    @Published var canGoBack: Bool = false
    
    func navigateTo(_ view: String) {
        navigationHistory.append(currentView)
        currentView = view
        canGoBack = !navigationHistory.isEmpty
    }
    
    func goBack() {
        if let previousView = navigationHistory.popLast() {
            currentView = previousView
            canGoBack = !navigationHistory.isEmpty
        }
    }
    
    func reset() {
        currentView = "Dashboard"
        navigationHistory = []
        canGoBack = false
    }
}

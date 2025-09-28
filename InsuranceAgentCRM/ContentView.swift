import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var firebaseManager: FirebaseManager
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
                    .environmentObject(firebaseManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            print("🔍 ContentView appeared with context: \(viewContext)")
            print("🔍 Context persistent store coordinator: \(String(describing: viewContext.persistentStoreCoordinator))")
            print("🔍 Context persistent stores: \(viewContext.persistentStoreCoordinator?.persistentStores.count ?? 0)")
            authManager.checkAuthenticationStatus()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var firebaseManager: FirebaseManager
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                DashboardView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Dashboard")
                    }
                
                ClientsView()
                    .tabItem {
                        Image(systemName: "person.2.fill")
                        Text("Clients")
                    }
                
                TasksView()
                    .tabItem {
                        Image(systemName: "checklist")
                        Text("Tasks")
                    }
                
                ProductsView()
                    .tabItem {
                        Image(systemName: "shippingbox.fill")
                        Text("Products")
                    }
                
                ReportsView()
                    .tabItem {
                        Image(systemName: "chart.bar.fill")
                        Text("Reports")
                    }
            }
            
            // Sync Status Bar
            if !firebaseManager.isConnected {
                SyncStatusView()
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}


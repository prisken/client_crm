import SwiftUI
import CoreData

// MARK: - Client Detail View Model
class ClientDetailViewModel: ObservableObject {
    // This ViewModel no longer manages tasks; it's reserved for other client detail states
    @Published var isLoading = false
    @Published var errorMessage: String?
}

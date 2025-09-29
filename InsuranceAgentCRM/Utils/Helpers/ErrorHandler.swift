import Foundation
import SwiftUI

// MARK: - Error Types
enum AppError: LocalizedError {
    case networkError(String)
    case dataError(String)
    case validationError(String)
    case authenticationError(String)
    case firebaseError(String)
    case coreDataError(String)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .firebaseError(let message):
            return "Firebase Error: \(message)"
        case .coreDataError(let message):
            return "Core Data Error: \(message)"
        case .unknown(let message):
            return "Unknown Error: \(message)"
        }
    }
}

// MARK: - Error Handler
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    func handle(_ error: Error) {
        DispatchQueue.main.async {
            if let appError = error as? AppError {
                self.currentError = appError
            } else {
                self.currentError = .unknown(error.localizedDescription)
            }
            self.isShowingError = true
        }
    }
    
    func handle(_ appError: AppError) {
        DispatchQueue.main.async {
            self.currentError = appError
            self.isShowingError = true
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.isShowingError = false
        }
    }
}

// MARK: - Error View
struct ErrorView: View {
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    
    init(error: AppError, onRetry: (() -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 12) {
                if let onDismiss = onDismiss {
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .buttonStyle(.bordered)
                }
                
                if let onRetry = onRetry {
                    Button("Retry") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}

// MARK: - Error Alert
struct ErrorAlert: ViewModifier {
    @Binding var isPresented: Bool
    let error: AppError?
    let onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $isPresented) {
                if let onRetry = onRetry {
                    Button("Retry") {
                        onRetry()
                    }
                }
                Button("OK") {
                    isPresented = false
                }
            } message: {
                if let error = error {
                    Text(error.localizedDescription)
                }
            }
    }
}

// MARK: - View Extensions
extension View {
    func errorAlert(isPresented: Binding<Bool>, error: AppError?, onRetry: (() -> Void)? = nil) -> some View {
        self.modifier(ErrorAlert(isPresented: isPresented, error: error, onRetry: onRetry))
    }
    
    func errorOverlay(_ error: AppError?, onRetry: (() -> Void)? = nil) -> some View {
        self.overlay(
            Group {
                if let error = error {
                    ErrorView(error: error, onRetry: onRetry)
                        .padding()
                        .background(Color.black.opacity(0.3))
                }
            }
        )
    }
}

// MARK: - Logging (moved to Logger.swift)
// All logging functions are now available in Logger.swift
import Foundation
import SwiftUI

// MARK: - App Error Protocol
protocol AppError: Error, LocalizedError {
    var title: String { get }
    var message: String { get }
    var recoverySuggestion: String? { get }
}

// MARK: - Authentication Errors
enum AuthenticationError: AppError {
    case userNotFound
    case invalidCredentials
    case accountLocked
    case sessionExpired
    case networkError
    
    var title: String {
        switch self {
        case .userNotFound:
            return "User Not Found"
        case .invalidCredentials:
            return "Invalid Credentials"
        case .accountLocked:
            return "Account Locked"
        case .sessionExpired:
            return "Session Expired"
        case .networkError:
            return "Network Error"
        }
    }
    
    var message: String {
        switch self {
        case .userNotFound:
            return "No user found with the provided email address."
        case .invalidCredentials:
            return "The email or password you entered is incorrect."
        case .accountLocked:
            return "Your account has been locked. Please contact support."
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .networkError:
            return "Unable to connect to the server. Please check your internet connection."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .userNotFound:
            return "Please check your email address or create a new account."
        case .invalidCredentials:
            return "Please verify your email and password, or reset your password."
        case .accountLocked:
            return "Contact our support team to unlock your account."
        case .sessionExpired:
            return "Please log in again to continue."
        case .networkError:
            return "Check your internet connection and try again."
        }
    }
}

// MARK: - Data Errors
enum DataError: AppError {
    case saveFailed
    case fetchFailed
    case deleteFailed
    case validationFailed
    case syncFailed
    
    var title: String {
        switch self {
        case .saveFailed:
            return "Save Failed"
        case .fetchFailed:
            return "Fetch Failed"
        case .deleteFailed:
            return "Delete Failed"
        case .validationFailed:
            return "Validation Failed"
        case .syncFailed:
            return "Sync Failed"
        }
    }
    
    var message: String {
        switch self {
        case .saveFailed:
            return "Unable to save the data. Please try again."
        case .fetchFailed:
            return "Unable to retrieve the data. Please try again."
        case .deleteFailed:
            return "Unable to delete the item. Please try again."
        case .validationFailed:
            return "The data you entered is invalid. Please check your input."
        case .syncFailed:
            return "Unable to synchronize data. Please check your connection."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .saveFailed:
            return "Try saving again or contact support if the problem persists."
        case .fetchFailed:
            return "Refresh the data or restart the app."
        case .deleteFailed:
            return "Make sure the item is not in use and try again."
        case .validationFailed:
            return "Please correct the highlighted fields and try again."
        case .syncFailed:
            return "Check your internet connection and try syncing again."
        }
    }
}

// MARK: - Network Errors
enum NetworkError: AppError {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case unauthorized
    
    var title: String {
        switch self {
        case .noConnection:
            return "No Connection"
        case .timeout:
            return "Request Timeout"
        case .serverError:
            return "Server Error"
        case .invalidResponse:
            return "Invalid Response"
        case .unauthorized:
            return "Unauthorized"
        }
    }
    
    var message: String {
        switch self {
        case .noConnection:
            return "No internet connection available."
        case .timeout:
            return "The request timed out. Please try again."
        case .serverError(let code):
            return "Server error with code \(code)."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .unauthorized:
            return "You are not authorized to perform this action."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noConnection:
            return "Check your internet connection and try again."
        case .timeout:
            return "Try again in a moment or check your connection."
        case .serverError:
            return "The server is experiencing issues. Please try again later."
        case .invalidResponse:
            return "Please try again or contact support."
        case .unauthorized:
            return "Please log in again or contact support."
        }
    }
}

// MARK: - Error Handler
class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var isShowingError = false
    
    func handle(_ error: Error) {
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = UnknownError(error)
        }
        isShowingError = true
    }
    
    func clearError() {
        currentError = nil
        isShowingError = false
    }
}

// MARK: - Unknown Error
struct UnknownError: AppError {
    let underlyingError: Error
    
    init(_ error: Error) {
        self.underlyingError = error
    }
    
    var title: String {
        return "Unknown Error"
    }
    
    var message: String {
        return underlyingError.localizedDescription
    }
    
    var recoverySuggestion: String? {
        return "Please try again or contact support if the problem persists."
    }
}

// MARK: - Error View Modifier
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler: ErrorHandler
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.isShowingError
            ) {
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: {
                if let error = errorHandler.currentError {
                    Text(error.message)
                }
            }
    }
}

// MARK: - View Extension for Error Handling
extension View {
    func errorHandling(_ errorHandler: ErrorHandler) -> some View {
        self.modifier(ErrorAlertModifier(errorHandler: errorHandler))
    }
}

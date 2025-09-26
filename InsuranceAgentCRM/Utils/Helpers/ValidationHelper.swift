import Foundation
import SwiftUI

// MARK: - Validation Result
struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    
    init(isValid: Bool, errors: [ValidationError] = []) {
        self.isValid = isValid
        self.errors = errors
    }
}

// MARK: - Validation Error
struct ValidationError: LocalizedError {
    let field: String
    let message: String
    
    var errorDescription: String? {
        return "\(field): \(message)"
    }
}

// MARK: - Validation Helper
struct ValidationHelper {
    
    // MARK: - Email Validation
    static func validateEmail(_ email: String) -> ValidationResult {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if email.isEmpty {
            return ValidationResult(isValid: false, errors: [ValidationError(field: "Email", message: "Email is required")])
        }
        
        if !emailPredicate.evaluate(with: email) {
            return ValidationResult(isValid: false, errors: [ValidationError(field: "Email", message: "Please enter a valid email address")])
        }
        
        if email.count > AppConstants.Validation.maxEmailLength {
            return ValidationResult(isValid: false, errors: [ValidationError(field: "Email", message: "Email must be less than \(AppConstants.Validation.maxEmailLength) characters")])
        }
        
        return ValidationResult(isValid: true)
    }
    
    // MARK: - Name Validation
    static func validateName(_ name: String, fieldName: String = "Name") -> ValidationResult {
        if name.isEmpty {
            return ValidationResult(isValid: false, errors: [ValidationError(field: fieldName, message: "\(fieldName) is required")])
        }
        
        if name.count < AppConstants.Validation.minNameLength {
            return ValidationResult(isValid: false, errors: [ValidationError(field: fieldName, message: "\(fieldName) must be at least \(AppConstants.Validation.minNameLength) characters")])
        }
        
        if name.count > AppConstants.Validation.maxNameLength {
            return ValidationResult(isValid: false, errors: [ValidationError(field: fieldName, message: "\(fieldName) must be less than \(AppConstants.Validation.maxNameLength) characters")])
        }
        
        return ValidationResult(isValid: true)
    }
    
    // MARK: - Phone Validation
    static func validatePhone(_ phone: String) -> ValidationResult {
        if phone.isEmpty {
            return ValidationResult(isValid: false, errors: [ValidationError(field: "Phone", message: "Phone number is required")])
        }
        
        // Remove all non-digit characters for validation
        let digitsOnly = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digitsOnly.count < 10 {
            return ValidationResult(isValid: false, errors: [ValidationError(field: "Phone", message: "Phone number must be at least 10 digits")])
        }
        
        if phone.count > AppConstants.Validation.maxPhoneLength {
            return ValidationResult(isValid: false, errors: [ValidationError(field: "Phone", message: "Phone number must be less than \(AppConstants.Validation.maxPhoneLength) characters")])
        }
        
        return ValidationResult(isValid: true)
    }
    
    // MARK: - Password Validation
    static func validatePassword(_ password: String) -> ValidationResult {
        var errors: [ValidationError] = []
        
        if password.isEmpty {
            errors.append(ValidationError(field: "Password", message: "Password is required"))
        }
        
        if password.count < AppConstants.Validation.minPasswordLength {
            errors.append(ValidationError(field: "Password", message: "Password must be at least \(AppConstants.Validation.minPasswordLength) characters"))
        }
        
        if password.count > AppConstants.Validation.maxPasswordLength {
            errors.append(ValidationError(field: "Password", message: "Password must be less than \(AppConstants.Validation.maxPasswordLength) characters"))
        }
        
        // Check for at least one uppercase letter
        if password.range(of: "[A-Z]", options: .regularExpression) == nil {
            errors.append(ValidationError(field: "Password", message: "Password must contain at least one uppercase letter"))
        }
        
        // Check for at least one lowercase letter
        if password.range(of: "[a-z]", options: .regularExpression) == nil {
            errors.append(ValidationError(field: "Password", message: "Password must contain at least one lowercase letter"))
        }
        
        // Check for at least one digit
        if password.range(of: "[0-9]", options: .regularExpression) == nil {
            errors.append(ValidationError(field: "Password", message: "Password must contain at least one digit"))
        }
        
        return ValidationResult(isValid: errors.isEmpty, errors: errors)
    }
    
    // MARK: - Age Validation
    static func validateAge(_ age: Int16) -> ValidationResult {
        if age < 0 {
            return ValidationResult(isValid: false, errors: [ValidationError(field: "Age", message: "Age cannot be negative")])
        }
        
        if age > 120 {
            return ValidationResult(isValid: false, errors: [ValidationError(field: "Age", message: "Age must be less than 120")])
        }
        
        return ValidationResult(isValid: true)
    }
    
    // MARK: - Notes Validation
    static func validateNotes(_ notes: String) -> ValidationResult {
        if notes.count > AppConstants.Validation.maxNotesLength {
            return ValidationResult(isValid: false, errors: [ValidationError(field: "Notes", message: "Notes must be less than \(AppConstants.Validation.maxNotesLength) characters")])
        }
        
        return ValidationResult(isValid: true)
    }
    
    // MARK: - Client Validation
    static func validateClient(_ client: Client) -> ValidationResult {
        var allErrors: [ValidationError] = []
        
        // Validate first name
        let firstNameResult = validateName(client.firstName ?? "", fieldName: "First Name")
        allErrors.append(contentsOf: firstNameResult.errors)
        
        // Validate last name
        let lastNameResult = validateName(client.lastName ?? "", fieldName: "Last Name")
        allErrors.append(contentsOf: lastNameResult.errors)
        
        // Validate email if provided
        if let email = client.email, !email.isEmpty {
            let emailResult = validateEmail(email)
            allErrors.append(contentsOf: emailResult.errors)
        }
        
        // Validate phone
        let phoneResult = validatePhone(client.phone ?? "")
        allErrors.append(contentsOf: phoneResult.errors)
        
        // Validate age if provided
        if client.age > 0 {
            let ageResult = validateAge(client.age)
            allErrors.append(contentsOf: ageResult.errors)
        }
        
        // Validate notes if provided
        if let notes = client.notes, !notes.isEmpty {
            let notesResult = validateNotes(notes)
            allErrors.append(contentsOf: notesResult.errors)
        }
        
        return ValidationResult(isValid: allErrors.isEmpty, errors: allErrors)
    }
}

// MARK: - Validation View Modifier
struct ValidationModifier: ViewModifier {
    let validationResult: ValidationResult
    @Binding var showErrors: Bool
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content
            
            if showErrors && !validationResult.isValid {
                ForEach(validationResult.errors.indices, id: \.self) { index in
                    Text(validationResult.errors[index].message)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - View Extension for Validation
extension View {
    func validation(_ result: ValidationResult, showErrors: Binding<Bool>) -> some View {
        self.modifier(ValidationModifier(validationResult: result, showErrors: showErrors))
    }
}

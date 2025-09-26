import Foundation
import UIKit

extension String {
    // MARK: - Validation
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidPhone: Bool {
        let phoneRegex = "^[+]?[0-9]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self)
    }
    
    var isNotEmpty: Bool {
        !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Formatting
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst().lowercased()
    }
    
    var titleCased: String {
        components(separatedBy: " ")
            .map { $0.capitalizedFirst }
            .joined(separator: " ")
    }
    
    // MARK: - Phone Number Formatting
    var formattedPhone: String {
        let digits = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        if digits.count == 10 {
            return String(format: "(%@) %@-%@",
                        String(digits.prefix(3)),
                        String(digits.dropFirst(3).prefix(3)),
                        String(digits.suffix(4)))
        } else if digits.count == 11 && digits.hasPrefix("1") {
            let withoutCountryCode = String(digits.dropFirst())
            return String(format: "+1 (%@) %@-%@",
                        String(withoutCountryCode.prefix(3)),
                        String(withoutCountryCode.dropFirst(3).prefix(3)),
                        String(withoutCountryCode.suffix(4)))
        }
        
        return self
    }
    
    // MARK: - Initials
    var initials: String {
        components(separatedBy: " ")
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }
    
    // MARK: - Search Helpers
    func contains(_ searchText: String, caseSensitive: Bool = false) -> Bool {
        if caseSensitive {
            return self.range(of: searchText) != nil
        } else {
            return self.lowercased().range(of: searchText.lowercased()) != nil
        }
    }
    
    // MARK: - Truncation
    func truncated(to length: Int, trailing: String = "...") -> String {
        if count <= length {
            return self
        }
        return String(prefix(length - trailing.count)) + trailing
    }
    
    // MARK: - URL Helpers
    var isValidURL: Bool {
        guard let url = URL(string: self) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    // MARK: - Localization
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: arguments)
    }
}

// MARK: - Optional String Extensions
extension Optional where Wrapped == String {
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
    
    var orEmpty: String {
        self ?? ""
    }
    
    var orPlaceholder: String {
        self ?? "N/A"
    }
}

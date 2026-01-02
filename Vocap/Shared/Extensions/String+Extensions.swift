import Foundation

extension String {
    /// Capitalize the first letter only
    var capitalizedFirst: String {
        guard let first = first else { return self }
        return first.uppercased() + dropFirst()
    }
    
    /// Check if string is a valid email
    var isValidEmail: Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: emailRegex, options: .regularExpression) != nil
    }
    
    /// Trim whitespace and newlines
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check if string is empty or only whitespace
    var isBlank: Bool {
        trimmed.isEmpty
    }
    
    /// Truncate string to a maximum length with ellipsis
    func truncated(to maxLength: Int, trailing: String = "…") -> String {
        if count <= maxLength {
            return self
        }
        return String(prefix(maxLength - trailing.count)) + trailing
    }
}


import Foundation
import Security

/// A helper class for securely storing and retrieving data from the Keychain
final class KeychainHelper: Sendable {
    static let shared = KeychainHelper()
    
    private init() {}
    
    /// Keys for keychain items
    enum Keys {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let sessionExpiry = "sessionExpiry"
    }
    
    /// Save a string value to the keychain
    func save(_ value: String, forKey key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        try save(data, forKey: key)
    }
    
    /// Save data to the keychain
    func save(_ data: Data, forKey key: String) throws {
        // Delete any existing item first
        try? delete(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            // Enable sharing via App Group
            kSecAttrAccessGroup as String: Constants.appGroupIdentifier
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    /// Retrieve a string value from the keychain
    func getString(forKey key: String) throws -> String? {
        guard let data = try getData(forKey: key) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// Retrieve data from the keychain
    func getData(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecAttrAccessGroup as String: Constants.appGroupIdentifier
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.loadFailed(status)
        }
        
        return result as? Data
    }
    
    /// Delete an item from the keychain
    func delete(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: Constants.appGroupIdentifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
    
    /// Delete all items for this app
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.keychainService,
            kSecAttrAccessGroup as String: Constants.appGroupIdentifier
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Convenience methods for session management

extension KeychainHelper {
    /// Save the authentication session tokens
    func saveSession(accessToken: String, refreshToken: String, expiresAt: Date) throws {
        try save(accessToken, forKey: Keys.accessToken)
        try save(refreshToken, forKey: Keys.refreshToken)
        try save(String(expiresAt.timeIntervalSince1970), forKey: Keys.sessionExpiry)
    }
    
    /// Get the stored access token
    func getAccessToken() -> String? {
        try? getString(forKey: Keys.accessToken)
    }
    
    /// Get the stored refresh token
    func getRefreshToken() -> String? {
        try? getString(forKey: Keys.refreshToken)
    }
    
    /// Get the session expiry date
    func getSessionExpiry() -> Date? {
        guard let expiryString = try? getString(forKey: Keys.sessionExpiry),
              let timestamp = Double(expiryString) else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }
    
    /// Check if we have a valid session
    func hasValidSession() -> Bool {
        guard let _ = getAccessToken(),
              let expiryDate = getSessionExpiry() else {
            return false
        }
        return Date() < expiryDate
    }
    
    /// Clear all session data (for logout)
    func clearSession() throws {
        try delete(forKey: Keys.accessToken)
        try delete(forKey: Keys.refreshToken)
        try delete(forKey: Keys.sessionExpiry)
    }
}

enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for Keychain"
        case .saveFailed(let status):
            return "Failed to save to Keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from Keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from Keychain: \(status)"
        }
    }
}


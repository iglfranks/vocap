import Foundation

/// Provides access to the shared App Group container for data sharing between app and widgets
enum AppGroup {
    /// URL to the shared container directory
    static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: Constants.appGroupIdentifier
        )
    }
    
    /// UserDefaults instance for the shared App Group
    static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: Constants.appGroupIdentifier)
    }
    
    /// URL for the shared SwiftData store
    static var swiftDataURL: URL? {
        containerURL?.appendingPathComponent("Library/Application Support/Vocap.store")
    }
    
    /// Save a Codable object to the shared container
    static func save<T: Codable>(_ object: T, forKey key: String) throws {
        guard let userDefaults = userDefaults else {
            throw AppGroupError.containerNotAvailable
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(object)
        userDefaults.set(data, forKey: key)
    }
    
    /// Load a Codable object from the shared container
    static func load<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let userDefaults = userDefaults else {
            throw AppGroupError.containerNotAvailable
        }
        
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
    
    /// Remove an object from the shared container
    static func remove(forKey key: String) {
        userDefaults?.removeObject(forKey: key)
    }
    
    /// Keys for shared data
    enum Keys {
        /// Array of words for widget display
        static let widgetWords = "widgetWords"
        
        /// Current user session info
        static let currentUser = "currentUser"
        
        /// Last widget update timestamp
        static let lastWidgetUpdate = "lastWidgetUpdate"
    }
}

enum AppGroupError: Error, LocalizedError {
    case containerNotAvailable
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .containerNotAvailable:
            return "App Group container is not available"
        case .encodingFailed:
            return "Failed to encode data for App Group"
        case .decodingFailed:
            return "Failed to decode data from App Group"
        }
    }
}


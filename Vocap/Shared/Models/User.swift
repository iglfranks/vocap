import Foundation

/// Represents the authenticated user profile
struct User: Codable, Identifiable, Sendable {
    let id: UUID
    let email: String
    let createdAt: Date
    var displayName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case createdAt = "created_at"
        case displayName = "display_name"
    }
}

/// Represents the current authentication state
enum AuthState: Equatable {
    case unknown
    case unauthenticated
    case authenticating
    case authenticated(User)
    case magicLinkSent(email: String)
    
    var isAuthenticated: Bool {
        if case .authenticated = self {
            return true
        }
        return false
    }
    
    var user: User? {
        if case .authenticated(let user) = self {
            return user
        }
        return nil
    }
}

/// Session data from Supabase
struct Session: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case user
    }
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}


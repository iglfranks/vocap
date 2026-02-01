import Foundation

/// Represents the authenticated user
/// With CloudKit, user identity is managed by iCloud account
struct CloudUser: Sendable, Equatable, Codable {
    /// iCloud user record ID
    let userRecordID: String

    /// Apple ID from Sign in with Apple (if used)
    let appleUserID: String?

    /// User's display name (from Sign in with Apple)
    var displayName: String?

    /// User's email (only available with Sign in with Apple)
    var email: String?

    /// Whether the user is using anonymous iCloud auth (no Sign in with Apple)
    var isAnonymous: Bool {
        appleUserID == nil
    }

    init(
        userRecordID: String,
        appleUserID: String? = nil,
        displayName: String? = nil,
        email: String? = nil
    ) {
        self.userRecordID = userRecordID
        self.appleUserID = appleUserID
        self.displayName = displayName
        self.email = email
    }
}

/// Represents the current authentication state
enum AuthState: Equatable {
    case unknown
    case checking
    case signedIn(CloudUser)
    case signedOut
    case iCloudUnavailable(reason: String)

    var isSignedIn: Bool {
        if case .signedIn = self {
            return true
        }
        return false
    }

    var user: CloudUser? {
        if case .signedIn(let user) = self {
            return user
        }
        return nil
    }

    // Equatable conformance for iCloudUnavailable
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.unknown, .unknown):
            return true
        case (.checking, .checking):
            return true
        case (.signedOut, .signedOut):
            return true
        case (.signedIn(let user1), .signedIn(let user2)):
            return user1 == user2
        case (.iCloudUnavailable(let reason1), .iCloudUnavailable(let reason2)):
            return reason1 == reason2
        default:
            return false
        }
    }
}

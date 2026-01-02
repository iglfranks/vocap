import Foundation
import Supabase

/// Handles authentication via Supabase magic link
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    /// Current authentication state
    @Published private(set) var authState: AuthState = .unknown
    
    /// Current authenticated user
    @Published private(set) var currentUser: User?
    
    /// Error message for display
    @Published var errorMessage: String?
    
    private let keychain = KeychainHelper.shared
    
    private init() {
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Magic Link Authentication
    
    /// Send a magic link to the user's email
    func sendMagicLink(to email: String) async throws {
        authState = .authenticating
        errorMessage = nil
        
        do {
            try await supabase.auth.signInWithOTP(
                email: email,
                redirectTo: Constants.Supabase.redirectURL
            )
            
            authState = .magicLinkSent(email: email)
        } catch {
            authState = .unauthenticated
            errorMessage = error.localizedDescription
            throw AuthError.magicLinkFailed(error.localizedDescription)
        }
    }
    
    /// Handle the magic link callback URL
    func handleMagicLinkCallback(url: URL) async throws {
        authState = .authenticating
        errorMessage = nil
        
        do {
            // Extract the token from the URL
            let session = try await supabase.auth.session(from: url)
            try await handleSession(session)
        } catch {
            authState = .unauthenticated
            errorMessage = error.localizedDescription
            throw AuthError.callbackFailed(error.localizedDescription)
        }
    }
    
    /// Check for existing valid session on app launch
    func checkExistingSession() async {
        // First check keychain for stored tokens
        if keychain.hasValidSession(),
           let accessToken = keychain.getAccessToken() {
            do {
                // Try to restore session with Supabase
                let session = try await supabase.auth.session
                try await handleSession(session)
                return
            } catch {
                // Session invalid, clear and continue to unauthenticated
                try? keychain.clearSession()
            }
        }
        
        // Check if Supabase has a valid session
        do {
            let session = try await supabase.auth.session
            try await handleSession(session)
        } catch {
            authState = .unauthenticated
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
            try keychain.clearSession()
            AppGroup.remove(forKey: AppGroup.Keys.currentUser)
            
            currentUser = nil
            authState = .unauthenticated
        } catch {
            errorMessage = error.localizedDescription
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }
    
    /// Refresh the session if needed
    func refreshSessionIfNeeded() async throws {
        guard let expiryDate = keychain.getSessionExpiry() else {
            throw AuthError.noSession
        }
        
        // Refresh if session expires within 5 minutes
        let refreshThreshold = Date().addingTimeInterval(5 * 60)
        
        if expiryDate < refreshThreshold {
            let session = try await supabase.auth.refreshSession()
            try await handleSession(session)
        }
    }
    
    // MARK: - Private Helpers
    
    private func handleSession(_ session: Auth.Session) async throws {
        // Convert expiresAt from TimeInterval to Date
        let expiresAtDate = Date(timeIntervalSince1970: session.expiresAt)
        
        // Store tokens securely
        try keychain.saveSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: expiresAtDate
        )
        
        // Create user object from Supabase user
        let user = User(
            id: session.user.id,
            email: session.user.email ?? "",
            createdAt: session.user.createdAt
        )
        
        // Store user for widget access
        try? AppGroup.save(user, forKey: AppGroup.Keys.currentUser)
        
        currentUser = user
        authState = .authenticated(user)
    }
}

// MARK: - Errors

enum AuthError: Error, LocalizedError {
    case magicLinkFailed(String)
    case callbackFailed(String)
    case signOutFailed(String)
    case noSession
    case invalidSession
    
    var errorDescription: String? {
        switch self {
        case .magicLinkFailed(let message):
            return "Failed to send magic link: \(message)"
        case .callbackFailed(let message):
            return "Failed to authenticate: \(message)"
        case .signOutFailed(let message):
            return "Failed to sign out: \(message)"
        case .noSession:
            return "No active session"
        case .invalidSession:
            return "Session is invalid or expired"
        }
    }
}


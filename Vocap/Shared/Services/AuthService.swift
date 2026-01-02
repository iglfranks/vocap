import Foundation
import Supabase
import SwiftUI

/// Service for handling Supabase authentication
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var currentUser: User?
    
    private init() {
        Task {
            await checkExistingSession()
        }
    }
    
    /// Check if there's an existing session on app launch
    func checkExistingSession() async {
        do {
            let session = try await supabase.auth.session
            
            await handleSession(session)
        } catch {
            print("Error checking session: \(error)")
            authState = .unauthenticated
        }
    }
    
    /// Send magic link to email
    func sendMagicLink(to email: String) async throws {
        authState = .authenticating
        
        do {
            try await supabase.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: "vocap://auth/callback")
            )
            
            authState = .magicLinkSent(email: email)
        } catch {
            authState = .unauthenticated
            throw AuthError.sendMagicLinkFailed(error.localizedDescription)
        }
    }
    
    /// Handle magic link callback URL
    func handleMagicLinkCallback(url: URL) async throws {
        authState = .authenticating
        
        do {
            // Extract token from URL
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let fragment = components.fragment else {
                throw AuthError.invalidCallbackURL
            }
            
            // Parse the fragment to get access_token
            let params = fragment.components(separatedBy: "&")
            var accessToken: String?
            var refreshToken: String?
            
            for param in params {
                let parts = param.components(separatedBy: "=")
                if parts.count == 2 {
                    if parts[0] == "access_token" {
                        accessToken = parts[1]
                    } else if parts[0] == "refresh_token" {
                        refreshToken = parts[1]
                    }
                }
            }
            
            guard let token = accessToken else {
                throw AuthError.invalidCallbackURL
            }
            
            // Set the session with the token
            let session = try await supabase.auth.setSession(
                accessToken: token,
                refreshToken: refreshToken ?? ""
            )
            
            await handleSession(session)
            
        } catch {
            authState = .unauthenticated
            throw AuthError.callbackFailed(error.localizedDescription)
        }
    }
    
    /// Handle a valid session
    private func handleSession(_ session: Session) async {
        do {
            // Fetch user profile from Supabase
            let user = session.user
            
            // Convert Supabase user to our User model
            // Extract display_name from userMetadata if available
            let displayName: String? = {
                guard let metadata = user.userMetadata["display_name"] else {
                    return nil
                }
                // Try to extract string value from AnyJSON
                if case .string(let value) = metadata {
                    return value
                }
                return nil
            }()
            
            let appUser = User(
                id: UUID(uuidString: user.id.uuidString) ?? UUID(),
                email: user.email ?? "",
                createdAt: user.createdAt ?? Date(),
                displayName: displayName
            )
            
            currentUser = appUser
            authState = .authenticated(appUser)
            
            // Store tokens in keychain
            try? KeychainHelper.shared.save(session.accessToken, forKey: KeychainHelper.Keys.accessToken)
            try? KeychainHelper.shared.save(session.refreshToken, forKey: KeychainHelper.Keys.refreshToken)
            
        } catch {
            print("Error handling session: \(error)")
            authState = .unauthenticated
        }
    }
    
    /// Sign out the current user
    func signOut() async throws {
        do {
            try await supabase.auth.signOut()
            
            // Clear keychain
            try? KeychainHelper.shared.delete(forKey: KeychainHelper.Keys.accessToken)
            try? KeychainHelper.shared.delete(forKey: KeychainHelper.Keys.refreshToken)
            
            currentUser = nil
            authState = .unauthenticated
        } catch {
            throw AuthError.signOutFailed(error.localizedDescription)
        }
    }
}

// MARK: - Errors

enum AuthError: Error, LocalizedError {
    case sendMagicLinkFailed(String)
    case invalidCallbackURL
    case callbackFailed(String)
    case signOutFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .sendMagicLinkFailed(let message):
            return "Failed to send magic link: \(message)"
        case .invalidCallbackURL:
            return "Invalid callback URL"
        case .callbackFailed(let message):
            return "Failed to complete sign in: \(message)"
        case .signOutFailed(let message):
            return "Failed to sign out: \(message)"
        }
    }
}


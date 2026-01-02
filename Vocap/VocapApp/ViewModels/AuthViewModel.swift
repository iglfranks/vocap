import Foundation
import SwiftUI

/// ViewModel for authentication state and actions
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published State

    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var authState: AuthViewState = .login

    // MARK: - Services

    private let authService = AuthService.shared

    // MARK: - Computed Properties

    var isAuthenticated: Bool {
        authService.authState.isAuthenticated
    }

    var currentUser: User? {
        authService.currentUser
    }

    var isValidEmail: Bool {
        email.isValidEmail
    }

    var canSubmit: Bool {
        isValidEmail && !isLoading
    }

    // MARK: - Initialization

    init() {
        // Check for existing session on launch
        Task {
            await checkExistingSession()
        }
        
        // Sync auth state from AuthService
        syncAuthState()
    }
    
    /// Sync auth state from AuthService to this ViewModel
    private func syncAuthState() {
        switch authService.authState {
        case .authenticated(let user):
            authState = .authenticated
        case .magicLinkSent(let email):
            self.email = email
            authState = .magicLinkSent
        case .unauthenticated, .unknown:
            authState = .login
        case .authenticating:
            // Keep current state while authenticating
            break
        }
    }

    // MARK: - Actions

    /// Check for existing session on launch
    func checkExistingSession() async {
        isLoading = true
        await authService.checkExistingSession()
        syncAuthState()
        isLoading = false
    }

    /// Send magic link to email
    func sendMagicLink() async {
        guard canSubmit else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.sendMagicLink(to: email)
            syncAuthState()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Handle magic link callback URL
    func handleMagicLinkCallback(url: URL) async {
        isLoading = true
        errorMessage = nil

        do {
            try await authService.handleMagicLinkCallback(url: url)
            syncAuthState()
        } catch {
            errorMessage = error.localizedDescription
            syncAuthState()
        }

        isLoading = false
    }

    /// Sign out
    func signOut() async {
        isLoading = true

        do {
            try await authService.signOut()
            syncAuthState()
            email = ""
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Go back to login screen
    func backToLogin() {
        authState = .login
        errorMessage = nil
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - View State

enum AuthViewState: Equatable {
    case login
    case magicLinkSent
    case authenticated
}


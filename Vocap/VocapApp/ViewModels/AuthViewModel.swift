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
        // Observe auth service state changes
        Task {
            await checkExistingSession()
        }
    }

    // MARK: - Actions

    /// Check for existing session on launch
    func checkExistingSession() async {
        isLoading = true
        await authService.checkExistingSession()

        if authService.authState.isAuthenticated {
            authState = .authenticated
        }
        isLoading = false
    }

    /// Send magic link to email
    func sendMagicLink() async {
        guard canSubmit else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await authService.sendMagicLink(to: email)
            authState = .magicLinkSent
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
            authState = .authenticated
        } catch {
            errorMessage = error.localizedDescription
            authState = .login
        }

        isLoading = false
    }

    /// Sign out
    func signOut() async {
        isLoading = true

        do {
            try await authService.signOut()
            authState = .login
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

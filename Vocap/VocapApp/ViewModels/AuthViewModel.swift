import AuthenticationServices
import Foundation
import SwiftUI

/// ViewModel for CloudKit/Sign in with Apple authentication
@MainActor
final class AuthViewModel: ObservableObject {
    // MARK: - Published State

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Services

    private let authService = CloudKitAuthService.shared

    // MARK: - Computed Properties

    var authState: AuthState {
        authService.authState
    }

    var currentUser: CloudUser? {
        authService.currentUser
    }

    var isSignedIn: Bool {
        authState.isSignedIn
    }

    // MARK: - Initialization

    init() {
        Task {
            await checkiCloudStatus()
        }
    }

    // MARK: - Actions

    /// Check iCloud account status
    func checkiCloudStatus() async {
        isLoading = true
        await authService.checkiCloudStatus()
        isLoading = false
    }

    /// Handle Sign in with Apple result
    func handleSignInWithApple(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil

        await authService.handleSignInWithApple(result: result)

        if case .failure(let error) = result {
            // Don't show error for user cancellation
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    /// Sign out
    func signOut() {
        authService.signOut()
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}

// MARK: - View State

enum AuthViewState: Equatable {
    case loading
    case signedIn
    case signedOut
    case iCloudUnavailable(String)
}

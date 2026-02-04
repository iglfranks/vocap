import AuthenticationServices
import CloudKit
import Foundation
import os.log

/// Service for handling iCloud authentication and Sign in with Apple
@MainActor
final class CloudKitAuthService: ObservableObject {
    static let shared = CloudKitAuthService()

    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var currentUser: CloudUser?

    private let container: CKContainer
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.vocap.app", category: "CloudKitAuth")

    private init() {
        self.container = CKContainer(identifier: Constants.cloudKitContainerID)
        Task {
            await checkiCloudStatus()
        }
    }

    /// Check iCloud account status on launch
    func checkiCloudStatus() async {
        authState = .checking

        do {
            let status = try await container.accountStatus()

            switch status {
            case .available:
                // iCloud is available, get user record
                let userRecordID = try await container.userRecordID()
                let user = CloudUser(
                    userRecordID: userRecordID.recordName,
                    appleUserID: loadSavedAppleUserID(),
                    displayName: loadSavedDisplayName(),
                    email: loadSavedEmail()
                )
                currentUser = user
                authState = .signedIn(user)

            case .noAccount:
                authState = .iCloudUnavailable(
                    reason: "No iCloud account. Please sign in to iCloud in Settings.")

            case .restricted:
                authState = .iCloudUnavailable(
                    reason: "iCloud access is restricted on this device.")

            case .couldNotDetermine:
                authState = .iCloudUnavailable(reason: "Could not determine iCloud status.")

            case .temporarilyUnavailable:
                authState = .iCloudUnavailable(reason: "iCloud is temporarily unavailable.")

            @unknown default:
                authState = .iCloudUnavailable(reason: "Unknown iCloud status.")
            }
        } catch {
            authState = .iCloudUnavailable(reason: error.localizedDescription)
        }
    }

    /// Handle Sign in with Apple result
    func handleSignInWithApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential
            {
                let userID = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName
                let displayName =
                    [fullName?.givenName, fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")

                // Save to UserDefaults for persistence
                saveAppleUserID(userID)
                if let email = email {
                    saveEmail(email)
                }
                if !displayName.isEmpty {
                    saveDisplayName(displayName)
                }

                // Refresh auth state
                await checkiCloudStatus()
            }

        case .failure(let error):
            // Use os_log with private flag to prevent sensitive error details from appearing in device logs
            logger.error("Sign in with Apple failed: \(error.localizedDescription, privacy: .private)")
        }
    }

    /// Sign out (clears local Apple ID data)
    /// Note: iCloud sync continues even after "sign out" since it's tied to the iCloud account
    func signOut() {
        clearSavedAppleData()
        currentUser = nil
        authState = .signedOut
    }

    // MARK: - Private Helpers (UserDefaults persistence)

    private var userDefaults: UserDefaults {
        AppGroup.userDefaults ?? UserDefaults.standard
    }

    private func saveAppleUserID(_ id: String) {
        userDefaults.set(id, forKey: "appleUserID")
    }

    private func loadSavedAppleUserID() -> String? {
        userDefaults.string(forKey: "appleUserID")
    }

    private func saveEmail(_ email: String) {
        userDefaults.set(email, forKey: "userEmail")
    }

    private func loadSavedEmail() -> String? {
        userDefaults.string(forKey: "userEmail")
    }

    private func saveDisplayName(_ name: String) {
        userDefaults.set(name, forKey: "userDisplayName")
    }

    private func loadSavedDisplayName() -> String? {
        userDefaults.string(forKey: "userDisplayName")
    }

    private func clearSavedAppleData() {
        userDefaults.removeObject(forKey: "appleUserID")
        userDefaults.removeObject(forKey: "userEmail")
        userDefaults.removeObject(forKey: "userDisplayName")
    }
}

// MARK: - Auth Errors

enum CloudKitAuthError: Error, LocalizedError {
    case iCloudUnavailable(String)
    case signInFailed(String)

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable(let reason):
            return "iCloud is unavailable: \(reason)"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        }
    }
}

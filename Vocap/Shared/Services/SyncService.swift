import Foundation
import Supabase

/// Service for syncing local data with Supabase
@MainActor
final class SyncService: ObservableObject {
    static let shared = SyncService()
    
    @Published private(set) var isSyncing = false
    @Published private(set) var lastSyncDate: Date?
    @Published var errorMessage: String?
    
    private let wordBankService = WordBankService.shared
    private let authService = AuthService.shared
    
    private init() {
        // Load last sync date from UserDefaults
        lastSyncDate = AppGroup.userDefaults?.object(forKey: Constants.UserDefaultsKeys.lastSyncDate) as? Date
    }
    
    // MARK: - Full Sync
    
    /// Perform a full sync with the server
    func performFullSync() async throws {
        guard authService.authState.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        isSyncing = true
        errorMessage = nil
        
        defer { isSyncing = false }
        
        do {
            // Fetch all data from server
            try await wordBankService.fetchWords()
            
            // Sync notification settings
            try await syncNotificationSettings()
            
            // Update last sync date
            lastSyncDate = Date()
            AppGroup.userDefaults?.set(lastSyncDate, forKey: Constants.UserDefaultsKeys.lastSyncDate)
            
        } catch {
            errorMessage = error.localizedDescription
            throw SyncError.syncFailed(error.localizedDescription)
        }
    }
    
    /// Sync notification settings from server
    private func syncNotificationSettings() async throws {
        guard let userId = authService.currentUser?.id else { return }
        
        do {
            let response: [NotificationScheduleDTO] = try await supabase
                .from("notification_settings")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            if let settings = response.first {
                // Store locally for use
                try? AppGroup.save(settings, forKey: "notificationSettings")
            }
        } catch {
            // Non-critical error, just log it
            print("Failed to sync notification settings: \(error)")
        }
    }
    
    // MARK: - Background Sync
    
    /// Perform a background sync (lighter weight)
    func performBackgroundSync() async {
        guard authService.authState.isAuthenticated else { return }
        
        do {
            try await wordBankService.fetchWords()
            lastSyncDate = Date()
            AppGroup.userDefaults?.set(lastSyncDate, forKey: Constants.UserDefaultsKeys.lastSyncDate)
        } catch {
            print("Background sync failed: \(error)")
        }
    }
    
    /// Check if sync is needed (e.g., last sync was > 1 hour ago)
    var needsSync: Bool {
        guard let lastSync = lastSyncDate else { return true }
        let hourAgo = Date().addingTimeInterval(-3600)
        return lastSync < hourAgo
    }
}

// MARK: - Errors

enum SyncError: Error, LocalizedError {
    case notAuthenticated
    case syncFailed(String)
    case conflictDetected
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to sync your data"
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .conflictDetected:
            return "A sync conflict was detected"
        }
    }
}


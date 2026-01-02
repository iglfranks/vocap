import Foundation

/// App-wide constants and configuration
enum Constants {
    /// App Group identifier for sharing data between app and widgets
    static let appGroupIdentifier = "group.com.vocap.app"

    /// Keychain service identifier
    static let keychainService = "com.vocap.app"

    /// Supabase configuration
    /// Secrets are loaded from Secrets.swift (gitignored)
    enum Supabase {
        /// Supabase project URL (loaded from Secrets.swift)
        static var url: URL {
            guard let url = URL(string: Secrets.supabaseURL),
                !Secrets.supabaseURL.contains("YOUR_")
            else {
                fatalError(
                    """
                    ⚠️ Supabase URL not configured!
                    Please copy Secrets.example.swift to Secrets.swift and add your credentials.
                    See README.md for setup instructions.
                    """)
            }
            return url
        }

        /// Supabase anon key (loaded from Secrets.swift)
        static var anonKey: String {
            guard !Secrets.supabaseAnonKey.contains("YOUR_") else {
                fatalError(
                    """
                    ⚠️ Supabase anon key not configured!
                    Please copy Secrets.example.swift to Secrets.swift and add your credentials.
                    See README.md for setup instructions.
                    """)
            }
            return Secrets.supabaseAnonKey
        }

        /// Deep link URL scheme for magic link redirects
        static let redirectScheme = "vocap"

        /// Full redirect URL for magic link auth
        static let redirectURL = URL(string: "\(redirectScheme)://auth/callback")!
    }

    /// Dictionary API configuration
    enum DictionaryAPI {
        /// Free Dictionary API base URL
        static let baseURL = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en")!
    }

    /// Widget configuration
    enum Widget {
        /// How often the widget timeline refreshes (in hours)
        static let refreshIntervalHours = 1

        /// Widget kind identifiers
        static let smallWidgetKind = "VocapSmallWidget"
        static let mediumWidgetKind = "VocapMediumWidget"
        static let largeWidgetKind = "VocapLargeWidget"
    }

    /// Notification configuration
    enum Notifications {
        /// Category identifier for word reminder notifications
        static let wordReminderCategory = "WORD_REMINDER"

        /// Default notification settings
        static let defaultFrequencyHours = 4
        static let defaultStartHour = 9
        static let defaultEndHour = 21
    }

    /// User Defaults keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastSyncDate = "lastSyncDate"
        static let notificationsEnabled = "notificationsEnabled"
    }
}

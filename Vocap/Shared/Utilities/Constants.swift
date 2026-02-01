import Foundation

/// App-wide constants and configuration
enum Constants {
    /// App Group identifier for sharing data between app and widgets
    static let appGroupIdentifier = "group.com.vocap.app"

    /// CloudKit container identifier
    static let cloudKitContainerID = "iCloud.com.vocap.app"

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
        static let notificationsEnabled = "notificationsEnabled"
    }
}

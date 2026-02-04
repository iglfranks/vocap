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
        static let baseURL = URL(string: "https://freedictionaryapi.com/api/v1/entries/")!
        /// Default language code (ISO 639-1)
        static let defaultLanguage = "en"
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

    /// User Defaults keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
}

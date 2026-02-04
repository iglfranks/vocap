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

        /// Supported languages from the Free Dictionary API
        static let supportedLanguages: [Language] = [
            Language(code: "en", name: "English"),
            Language(code: "es", name: "Spanish"),
            Language(code: "fr", name: "French"),
            Language(code: "de", name: "German"),
            Language(code: "it", name: "Italian"),
            Language(code: "pt", name: "Portuguese"),
            Language(code: "nl", name: "Dutch"),
            Language(code: "sv", name: "Swedish"),
            Language(code: "pl", name: "Polish"),
            Language(code: "tr", name: "Turkish"),
            Language(code: "el", name: "Greek"),
            Language(code: "cs", name: "Czech"),
            Language(code: "da", name: "Danish"),
            Language(code: "fi", name: "Finnish"),
            Language(code: "hu", name: "Hungarian"),
            Language(code: "no", name: "Norwegian"),
            Language(code: "ro", name: "Romanian"),
            Language(code: "ca", name: "Catalan"),
            Language(code: "hr", name: "Croatian"),
            Language(code: "lt", name: "Lithuanian"),
            Language(code: "lv", name: "Latvian"),
            Language(code: "la", name: "Latin"),
            Language(code: "eo", name: "Esperanto"),
            Language(code: "ga", name: "Irish"),
            Language(code: "cy", name: "Welsh"),
            Language(code: "eu", name: "Basque"),
            Language(code: "gl", name: "Galician"),
        ]
    }

    /// Language model for dictionary API
    struct Language: Identifiable, Hashable {
        let code: String
        let name: String

        var id: String { code }
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

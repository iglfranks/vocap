import Foundation
import os.log

/// Service for fetching word definitions from the Free Dictionary API
final class DictionaryService: Sendable {
    static let shared = DictionaryService()

    private let session: URLSession
    private let baseURL = Constants.DictionaryAPI.baseURL
    private let language = Constants.DictionaryAPI.defaultLanguage
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.vocap.app", category: "DictionaryService")

    /// Maximum allowed length for search terms to prevent memory issues and API abuse
    static let maxSearchTermLength = 100

    /// Set of valid language codes from supported languages
    private static let validLanguageCodes: Set<String> = Set(
        Constants.DictionaryAPI.supportedLanguages.map { $0.code }
    )

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Search for a word's definition
    func lookupWord(_ term: String, language: String? = nil) async throws -> DictionaryResult {
        // Validate input length
        let trimmedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTerm.count <= Self.maxSearchTermLength else {
            throw DictionaryError.termTooLong(maxLength: Self.maxSearchTermLength)
        }

        guard !trimmedTerm.isEmpty else {
            throw DictionaryError.emptyTerm
        }

        // Validate language code against whitelist
        let lang = language ?? self.language
        guard Self.validLanguageCodes.contains(lang) else {
            throw DictionaryError.invalidLanguage(lang)
        }

        let cleanedTerm =
            trimmedTerm
            .lowercased()
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? trimmedTerm.lowercased()

        let url =
            baseURL
            .appendingPathComponent(lang)
            .appendingPathComponent(cleanedTerm)

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let result = try decoder.decode(FreeDictionaryResponse.self, from: data)

            guard !result.entries.isEmpty else {
                throw DictionaryError.noResults
            }

            // Sanitize and validate API response before returning
            return result.toSanitizedDictionaryResult()

        case 404:
            throw DictionaryError.wordNotFound(term)

        case 429:
            throw DictionaryError.rateLimitExceeded

        default:
            throw DictionaryError.serverError(httpResponse.statusCode)
        }
    }

    /// Search for words matching a prefix (for autocomplete)
    /// Note: Free Dictionary API doesn't support prefix search,
    /// so this is a placeholder for future enhancement
    func searchWords(prefix: String) async throws -> [String] {
        // For now, just try to look up the exact word
        // In the future, you could integrate a different API for suggestions
        do {
            let result = try await lookupWord(prefix)
            return [result.word]
        } catch DictionaryError.wordNotFound {
            return []
        }
    }
}

// MARK: - API Response Models

/// Response from the Free Dictionary API (freedictionaryapi.com)
struct FreeDictionaryResponse: Codable {
    let word: String
    let entries: [DictionaryEntry]
    let source: SourceInfo?

    struct DictionaryEntry: Codable {
        let language: LanguageInfo?
        let partOfSpeech: String
        let pronunciations: [Pronunciation]?
        let forms: [WordForm]?
        let senses: [Sense]
        let synonyms: [String]?
        let antonyms: [String]?
    }

    struct LanguageInfo: Codable {
        let code: String
        let name: String
    }

    struct Pronunciation: Codable {
        let type: String?
        let text: String?
        let tags: [String]?
    }

    struct WordForm: Codable {
        let word: String
        let tags: [String]?
    }

    struct Sense: Codable {
        let definition: String
        let examples: [String]?
        let quotes: [Quote]?
        let synonyms: [String]?
        let antonyms: [String]?
    }

    struct Quote: Codable {
        let text: String?
        let reference: String?
    }

    struct SourceInfo: Codable {
        let url: String?
        let license: LicenseInfo?

        struct LicenseInfo: Codable {
            let name: String?
            let url: String?
        }
    }

    /// Convert API response to our app's model
    func toDictionaryResult() -> DictionaryResult {
        toSanitizedDictionaryResult()
    }

    /// Convert API response to our app's model with sanitization
    /// Sanitizes all text fields to prevent potential security issues from malicious API responses
    func toSanitizedDictionaryResult() -> DictionaryResult {
        // Get the best phonetic text from the first entry's pronunciations
        let phoneticText = entries.first?.pronunciations?.first(where: { $0.text != nil })?.text

        // Get the first entry with its first sense
        let firstEntry = entries.first
        let firstSense = firstEntry?.senses.first

        // Collect all definitions across all entries with sanitization
        var allDefinitions: [DictionaryResult.Definition] = []
        for entry in entries {
            for sense in entry.senses {
                allDefinitions.append(
                    DictionaryResult.Definition(
                        text: Self.sanitize(sense.definition),
                        example: sense.examples?.first.map { Self.sanitize($0) },
                        partOfSpeech: Self.sanitize(entry.partOfSpeech)
                    ))
            }
        }

        return DictionaryResult(
            word: Self.sanitize(word),
            phonetic: phoneticText.map { Self.sanitize($0) },
            primaryDefinition: Self.sanitize(firstSense?.definition ?? ""),
            primaryPartOfSpeech: firstEntry.map { Self.sanitize($0.partOfSpeech) },
            primaryExample: firstSense?.examples?.first.map { Self.sanitize($0) },
            allDefinitions: allDefinitions
        )
    }

    /// Sanitize a string from external API response
    /// - Trims whitespace
    /// - Limits length to prevent memory issues
    /// - Removes control characters (except newlines/tabs for formatting)
    private static func sanitize(_ input: String, maxLength: Int = 10000) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // Limit length
        let truncated = trimmed.count > maxLength ? String(trimmed.prefix(maxLength)) : trimmed

        // Remove control characters except newline and tab (for text formatting)
        let allowedControlCharacters = CharacterSet(charactersIn: "\n\t")
        let controlCharacters = CharacterSet.controlCharacters.subtracting(allowedControlCharacters)

        return truncated.unicodeScalars
            .filter { !controlCharacters.contains($0) }
            .map { Character($0) }
            .reduce(into: "") { $0.append($1) }
    }
}

/// Simplified result model for use in the app
struct DictionaryResult: Sendable {
    let word: String
    let phonetic: String?
    let primaryDefinition: String
    let primaryPartOfSpeech: String?
    let primaryExample: String?
    let allDefinitions: [Definition]

    struct Definition: Sendable {
        let text: String
        let example: String?
        let partOfSpeech: String
    }

    /// Convert to a Word model for saving
    func toWord() -> Word {
        Word(
            term: word,
            definition: primaryDefinition,
            partOfSpeech: primaryPartOfSpeech,
            example: primaryExample,
            phonetic: phonetic
        )
    }
}

// MARK: - Errors

enum DictionaryError: Error, LocalizedError {
    case invalidResponse
    case wordNotFound(String)
    case noResults
    case serverError(Int)
    case networkError(Error)
    case rateLimitExceeded
    case termTooLong(maxLength: Int)
    case emptyTerm
    case invalidLanguage(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from dictionary service"
        case .wordNotFound(let word):
            return "Word '\(word)' not found in dictionary"
        case .noResults:
            return "No definitions found"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .rateLimitExceeded:
            return "Too many requests. Please try again later."
        case .termTooLong(let maxLength):
            return "Search term is too long. Maximum \(maxLength) characters allowed."
        case .emptyTerm:
            return "Please enter a word to search."
        case .invalidLanguage(let code):
            return "Unsupported language code: \(code)"
        }
    }
}

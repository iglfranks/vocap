import Foundation

/// Service for fetching word definitions from the Free Dictionary API
final class DictionaryService: Sendable {
    static let shared = DictionaryService()

    private let session: URLSession
    private let baseURL = Constants.DictionaryAPI.baseURL
    private let language = Constants.DictionaryAPI.defaultLanguage

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Search for a word's definition
    func lookupWord(_ term: String, language: String? = nil) async throws -> DictionaryResult {
        let cleanedTerm =
            term.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? term.lowercased()

        let lang = language ?? self.language
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

            return result.toDictionaryResult()

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
        // Get the best phonetic text from the first entry's pronunciations
        let phoneticText = entries.first?.pronunciations?.first(where: { $0.text != nil })?.text

        // Get the first entry with its first sense
        let firstEntry = entries.first
        let firstSense = firstEntry?.senses.first

        // Collect all definitions across all entries
        var allDefinitions: [DictionaryResult.Definition] = []
        for entry in entries {
            for sense in entry.senses {
                allDefinitions.append(
                    DictionaryResult.Definition(
                        text: sense.definition,
                        example: sense.examples?.first,
                        partOfSpeech: entry.partOfSpeech
                    ))
            }
        }

        return DictionaryResult(
            word: word,
            phonetic: phoneticText,
            primaryDefinition: firstSense?.definition ?? "",
            primaryPartOfSpeech: firstEntry?.partOfSpeech,
            primaryExample: firstSense?.examples?.first,
            allDefinitions: allDefinitions
        )
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
        }
    }
}

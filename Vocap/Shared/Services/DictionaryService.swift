import Foundation

/// Service for fetching word definitions from the Free Dictionary API
final class DictionaryService: Sendable {
    static let shared = DictionaryService()
    
    private let session: URLSession
    private let baseURL = Constants.DictionaryAPI.baseURL
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Search for a word's definition
    func lookupWord(_ term: String) async throws -> DictionaryResult {
        let cleanedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? term
        
        let url = baseURL.appendingPathComponent(cleanedTerm)
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw DictionaryError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200:
            let decoder = JSONDecoder()
            let results = try decoder.decode([DictionaryAPIResponse].self, from: data)
            
            guard let first = results.first else {
                throw DictionaryError.noResults
            }
            
            return first.toDictionaryResult()
            
        case 404:
            throw DictionaryError.wordNotFound(term)
            
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

/// Response from the Free Dictionary API
struct DictionaryAPIResponse: Codable {
    let word: String
    let phonetic: String?
    let phonetics: [PhoneticEntry]?
    let meanings: [MeaningEntry]
    let sourceUrls: [String]?
    
    struct PhoneticEntry: Codable {
        let text: String?
        let audio: String?
    }
    
    struct MeaningEntry: Codable {
        let partOfSpeech: String
        let definitions: [DefinitionEntry]
    }
    
    struct DefinitionEntry: Codable {
        let definition: String
        let example: String?
        let synonyms: [String]?
        let antonyms: [String]?
    }
    
    /// Convert API response to our app's model
    func toDictionaryResult() -> DictionaryResult {
        // Get the best phonetic text
        let phoneticText = phonetic ?? phonetics?.first(where: { $0.text != nil })?.text
        
        // Get the first meaning with its definition
        let firstMeaning = meanings.first
        let firstDefinition = firstMeaning?.definitions.first
        
        // Collect all definitions grouped by part of speech
        var allDefinitions: [DictionaryResult.Definition] = []
        for meaning in meanings {
            for def in meaning.definitions {
                allDefinitions.append(DictionaryResult.Definition(
                    text: def.definition,
                    example: def.example,
                    partOfSpeech: meaning.partOfSpeech
                ))
            }
        }
        
        return DictionaryResult(
            word: word,
            phonetic: phoneticText,
            primaryDefinition: firstDefinition?.definition ?? "",
            primaryPartOfSpeech: firstMeaning?.partOfSpeech,
            primaryExample: firstDefinition?.example,
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
        }
    }
}


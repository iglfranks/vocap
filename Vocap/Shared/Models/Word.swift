import Foundation
import SwiftData

/// Represents a vocabulary word in the user's word bank
@Model
final class Word {
    /// The vocabulary term
    var term: String = ""

    /// Primary definition of the word
    var definition: String = ""

    /// Part of speech (noun, verb, adjective, etc.)
    var partOfSpeech: String?

    /// Example sentence using the word
    var example: String?

    /// Phonetic pronunciation
    var phonetic: String?

    /// When the word was added to the bank
    var addedAt: Date = Date()

    /// When the word was last shown in a notification or widget
    var lastShownAt: Date?

    init(
        term: String,
        definition: String,
        partOfSpeech: String? = nil,
        example: String? = nil,
        phonetic: String? = nil,
        addedAt: Date = Date(),
        lastShownAt: Date? = nil
    ) {
        self.term = term
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.example = example
        self.phonetic = phonetic
        self.addedAt = addedAt
        self.lastShownAt = lastShownAt
    }
}

// MARK: - Snapshot for Widget/Notification serialization

/// Lightweight struct for passing word data to widgets via App Group
struct WordSnapshot: Codable, Identifiable, Sendable {
    let id: String
    let term: String
    let definition: String
    let partOfSpeech: String?
    let example: String?
    let phonetic: String?

    init(
        id: String,
        term: String,
        definition: String,
        partOfSpeech: String? = nil,
        example: String? = nil,
        phonetic: String? = nil
    ) {
        self.id = id
        self.term = term
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.example = example
        self.phonetic = phonetic
    }
}

extension Word {
    /// Convert to snapshot for widget/notification use
    func toSnapshot() -> WordSnapshot {
        WordSnapshot(
            id: persistentModelID.hashValue.description,
            term: term,
            definition: definition,
            partOfSpeech: partOfSpeech,
            example: example,
            phonetic: phonetic
        )
    }
}

import Foundation
import SwiftData

/// Represents a vocabulary word in the user's word bank
@Model
final class Word {
    /// Unique identifier for the word
    @Attribute(.unique) var id: UUID
    
    /// The vocabulary term
    var term: String
    
    /// Primary definition of the word
    var definition: String
    
    /// Part of speech (noun, verb, adjective, etc.)
    var partOfSpeech: String?
    
    /// Example sentence using the word
    var example: String?
    
    /// Phonetic pronunciation
    var phonetic: String?
    
    /// When the word was added to the bank
    var addedAt: Date
    
    /// When the word was last shown in a notification or widget
    var lastShownAt: Date?
    
    /// Remote ID from Supabase (for sync)
    var remoteId: UUID?
    
    /// Whether this word has been synced to the server
    var isSynced: Bool
    
    init(
        id: UUID = UUID(),
        term: String,
        definition: String,
        partOfSpeech: String? = nil,
        example: String? = nil,
        phonetic: String? = nil,
        addedAt: Date = Date(),
        lastShownAt: Date? = nil,
        remoteId: UUID? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.term = term
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.example = example
        self.phonetic = phonetic
        self.addedAt = addedAt
        self.lastShownAt = lastShownAt
        self.remoteId = remoteId
        self.isSynced = isSynced
    }
}

// MARK: - DTO for API/Supabase communication

/// Data transfer object for Word - used for API responses and Supabase sync
struct WordDTO: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID?
    let term: String
    let definition: String
    let partOfSpeech: String?
    let example: String?
    let phonetic: String?
    let addedAt: Date
    let lastShownAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case term
        case definition
        case partOfSpeech = "part_of_speech"
        case example
        case phonetic
        case addedAt = "added_at"
        case lastShownAt = "last_shown_at"
    }
    
    /// Convert DTO to SwiftData model
    func toModel() -> Word {
        Word(
            id: id,
            term: term,
            definition: definition,
            partOfSpeech: partOfSpeech,
            example: example,
            phonetic: phonetic,
            addedAt: addedAt,
            lastShownAt: lastShownAt,
            remoteId: id,
            isSynced: true
        )
    }
}

extension Word {
    /// Convert SwiftData model to DTO for API upload
    func toDTO(userId: UUID) -> WordDTO {
        WordDTO(
            id: remoteId ?? id,
            userId: userId,
            term: term,
            definition: definition,
            partOfSpeech: partOfSpeech,
            example: example,
            phonetic: phonetic,
            addedAt: addedAt,
            lastShownAt: lastShownAt
        )
    }
}


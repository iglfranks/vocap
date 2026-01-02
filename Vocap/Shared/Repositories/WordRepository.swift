import Foundation
import SwiftData

/// Repository for local word storage using SwiftData
/// Used for offline access and widget data
@MainActor
final class WordRepository {
    static let shared = WordRepository()

    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?

    private init() {
        setupContainer()
    }

    /// Set up the SwiftData container with App Group support
    private func setupContainer() {
        do {
            let schema = Schema([Word.self, NotificationSchedule.self])

            // Configure for App Group sharing
            var configuration: ModelConfiguration

            if let appGroupURL = AppGroup.swiftDataURL {
                configuration = ModelConfiguration(
                    schema: schema,
                    url: appGroupURL,
                    allowsSave: true
                )
            } else {
                // Fallback to default location
                configuration = ModelConfiguration(schema: schema)
            }

            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer?.mainContext

        } catch {
            print("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - CRUD Operations

    /// Save a word to local storage
    func save(_ word: Word) throws {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        context.insert(word)
        try context.save()
    }

    /// Save multiple words
    func saveAll(_ words: [Word]) throws {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        for word in words {
            context.insert(word)
        }

        try context.save()
    }

    /// Fetch all words
    func fetchAll() throws -> [Word] {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        let descriptor = FetchDescriptor<Word>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )

        return try context.fetch(descriptor)
    }

    /// Fetch a word by ID
    func fetch(id: UUID) throws -> Word? {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        let predicate = #Predicate<Word> { word in
            word.id == id
        }

        var descriptor = FetchDescriptor<Word>(predicate: predicate)
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    /// Fetch a word by term
    func fetch(term: String) throws -> Word? {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        let lowercasedTerm = term.lowercased()
        let predicate = #Predicate<Word> { word in
            word.term.localizedStandardContains(lowercasedTerm)
        }

        var descriptor = FetchDescriptor<Word>(predicate: predicate)
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }

    /// Delete a word
    func delete(_ word: Word) throws {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        context.delete(word)
        try context.save()
    }

    /// Delete a word by ID
    func delete(id: UUID) throws {
        guard let word = try fetch(id: id) else {
            return
        }
        try delete(word)
    }

    /// Delete all words
    func deleteAll() throws {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        try context.delete(model: Word.self)
        try context.save()
    }

    // MARK: - Random Words

    /// Get random words for widgets/notifications
    func getRandomWords(count: Int) throws -> [Word] {
        let allWords = try fetchAll()
        guard !allWords.isEmpty else { return [] }

        let shuffled = allWords.shuffled()
        return Array(shuffled.prefix(count))
    }

    /// Get least recently shown words
    func getLeastRecentlyShown(count: Int) throws -> [Word] {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        // Sort by lastShownAt ascending (nulls first)
        let descriptor = FetchDescriptor<Word>(
            sortBy: [SortDescriptor(\.lastShownAt, order: .forward)]
        )

        let words = try context.fetch(descriptor)
        return Array(words.prefix(count))
    }

    // MARK: - Sync Helpers

    /// Get words that haven't been synced
    func getUnsyncedWords() throws -> [Word] {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        let predicate = #Predicate<Word> { word in
            word.isSynced == false
        }

        let descriptor = FetchDescriptor<Word>(predicate: predicate)
        return try context.fetch(descriptor)
    }

    /// Mark a word as synced
    func markAsSynced(_ word: Word, remoteId: UUID) throws {
        word.isSynced = true
        word.remoteId = remoteId
        try modelContext?.save()
    }

    /// Update local words from DTOs (after sync)
    func updateFromDTOs(_ dtos: [WordDTO]) throws {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        // Delete existing words
        try context.delete(model: Word.self)

        // Insert new words from DTOs
        for dto in dtos {
            let word = dto.toModel()
            context.insert(word)
        }

        try context.save()
    }

    /// Get word count
    func count() throws -> Int {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }

        let descriptor = FetchDescriptor<Word>()
        return try context.fetchCount(descriptor)
    }
}

// MARK: - Errors

enum RepositoryError: Error, LocalizedError {
    case contextNotAvailable
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .contextNotAvailable:
            return "Database context is not available"
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete: \(message)"
        }
    }
}

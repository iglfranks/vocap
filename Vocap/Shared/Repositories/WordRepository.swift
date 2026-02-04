import Foundation
import SwiftData
import WidgetKit

/// Repository for word storage using SwiftData with CloudKit sync
@MainActor
final class WordRepository: ObservableObject {
    static let shared = WordRepository()

    /// Public access to the model container for SwiftUI
    let modelContainer: ModelContainer
    private var modelContext: ModelContext

    @Published private(set) var words: [Word] = []
    @Published private(set) var isLoading = false

    private init() {
        do {
            // Use persistent storage with CloudKit sync
            let schema = Schema([Word.self])
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(
                for: Word.self,
                configurations: configuration
            )

            modelContext = modelContainer.mainContext
            modelContext.autosaveEnabled = true

        } catch {
            fatalError(
                "Failed to create ModelContainer: \(error.localizedDescription)\n\nFull error: \(error)"
            )
        }
    }

    // MARK: - CRUD Operations

    /// Fetch all words from storage
    func fetchAll() async throws {
        isLoading = true
        defer { isLoading = false }

        let descriptor = FetchDescriptor<Word>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )

        words = try modelContext.fetch(descriptor)

        // Update widget data
        updateWidgetWords()
    }

    /// Save a word to storage
    func save(_ word: Word) throws {
        modelContext.insert(word)
        try modelContext.save()

        // Refresh local cache
        Task { try await fetchAll() }
    }

    /// Save multiple words
    func saveAll(_ words: [Word]) throws {
        for word in words {
            modelContext.insert(word)
        }
        try modelContext.save()

        // Refresh local cache
        Task { try await fetchAll() }
    }

    /// Fetch a word by ID
    func fetch(id: PersistentIdentifier) throws -> Word? {
        return try modelContext.fetch(FetchDescriptor<Word>()).first { $0.id == id }
    }

    /// Fetch a word by term
    func fetch(term: String) throws -> Word? {
        let lowercasedTerm = term.lowercased()
        let predicate = #Predicate<Word> { word in
            word.term.localizedStandardContains(lowercasedTerm)
        }

        var descriptor = FetchDescriptor<Word>(predicate: predicate)
        descriptor.fetchLimit = 1

        return try modelContext.fetch(descriptor).first
    }

    /// Delete a word
    func delete(_ word: Word) throws {
        modelContext.delete(word)
        try modelContext.save()

        // Refresh local cache
        Task { try await fetchAll() }
    }

    /// Delete a word by ID
    func delete(id: PersistentIdentifier) throws {
        guard let word = try fetch(id: id) else {
            return
        }
        try delete(word)
    }

    /// Delete all words
    func deleteAll() throws {
        try modelContext.delete(model: Word.self)
        try modelContext.save()

        // Refresh local cache
        Task { try await fetchAll() }
    }

    // MARK: - Query Helpers

    /// Get random words for widgets
    func getRandomWords(count: Int) -> [Word] {
        guard !words.isEmpty else { return [] }
        let shuffled = words.shuffled()
        return Array(shuffled.prefix(count))
    }

    /// Get word count
    func count() throws -> Int {
        let descriptor = FetchDescriptor<Word>()
        return try modelContext.fetchCount(descriptor)
    }

    // MARK: - Widget Support

    /// Update words in App Group for widget display
    private func updateWidgetWords() {
        let snapshots = getRandomWords(count: 24).map { $0.toSnapshot() }
        try? AppGroup.save(snapshots, forKey: AppGroup.Keys.widgetWords)
        WidgetCenter.shared.reloadAllTimelines()
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

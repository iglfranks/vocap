import Foundation
import Supabase

/// Service for managing the user's word bank (CRUD operations with Supabase)
///
/// Security: All queries are protected by Supabase Row Level Security (RLS).
/// The database policies ensure users can only access their own words.
/// Additionally, this service validates user ownership client-side as an extra safety layer.
@MainActor
final class WordBankService: ObservableObject {
    static let shared = WordBankService()

    @Published private(set) var words: [WordDTO] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let tableName = "words"
    private let authService = AuthService.shared

    private init() {}

    /// Get the current authenticated user's ID or throw
    private func requireUserId() throws -> UUID {
        guard let userId = authService.currentUser?.id else {
            throw WordBankError.notAuthenticated
        }
        return userId
    }

    // MARK: - Fetch Words

    /// Fetch all words for the current user
    /// Note: RLS ensures only the user's own words are returned
    func fetchWords() async throws {
        let userId = try requireUserId()

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Explicitly filter by user_id as defense-in-depth (RLS also enforces this)
            let response: [WordDTO] =
                try await supabase
                .from(tableName)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("added_at", ascending: false)
                .execute()
                .value

            words = response

            // Update widget data
            try? updateWidgetWords()
        } catch let error as WordBankError {
            throw error
        } catch {
            errorMessage = error.localizedDescription
            throw WordBankError.fetchFailed(error.localizedDescription)
        }
    }

    /// Fetch a single word by ID (must belong to current user)
    func fetchWord(id: UUID) async throws -> WordDTO? {
        let userId = try requireUserId()

        do {
            let response: [WordDTO] =
                try await supabase
                .from(tableName)
                .select()
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            return response.first
        } catch let error as WordBankError {
            throw error
        } catch {
            throw WordBankError.fetchFailed(error.localizedDescription)
        }
    }

    // MARK: - Add Words

    /// Add a new word to the current user's bank
    func addWord(_ word: Word) async throws -> WordDTO {
        let userId = try requireUserId()

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        let dto = word.toDTO(userId: userId)

        do {
            let response: WordDTO =
                try await supabase
                .from(tableName)
                .insert(dto)
                .select()
                .single()
                .execute()
                .value

            // Add to local cache
            words.insert(response, at: 0)

            // Update widget data
            try? updateWidgetWords()

            return response
        } catch {
            errorMessage = error.localizedDescription
            throw WordBankError.addFailed(error.localizedDescription)
        }
    }

    /// Add a word directly from a dictionary result
    func addWord(from result: DictionaryResult) async throws -> WordDTO {
        let word = result.toWord()
        return try await addWord(word)
    }

    // MARK: - Update Words

    /// Update a word's last shown timestamp
    /// Only updates if the word belongs to the current user
    func markWordAsShown(id: UUID) async throws {
        let userId = try requireUserId()

        do {
            // Explicitly filter by both id AND user_id for security
            try await supabase
                .from(tableName)
                .update(["last_shown_at": Date().ISO8601Format()])
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            // Update local cache
            if let index = words.firstIndex(where: { $0.id == id }) {
                // Create updated version
                let old = words[index]
                let updated = WordDTO(
                    id: old.id,
                    userId: old.userId,
                    term: old.term,
                    definition: old.definition,
                    partOfSpeech: old.partOfSpeech,
                    example: old.example,
                    phonetic: old.phonetic,
                    addedAt: old.addedAt,
                    lastShownAt: Date()
                )
                words[index] = updated
            }
        } catch let error as WordBankError {
            throw error
        } catch {
            throw WordBankError.updateFailed(error.localizedDescription)
        }
    }

    // MARK: - Delete Words

    /// Delete a word from the user's bank
    /// Only deletes if the word belongs to the current user
    func deleteWord(id: UUID) async throws {
        let userId = try requireUserId()

        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // Explicitly filter by both id AND user_id for security
            try await supabase
                .from(tableName)
                .delete()
                .eq("id", value: id.uuidString)
                .eq("user_id", value: userId.uuidString)
                .execute()

            // Remove from local cache
            words.removeAll { $0.id == id }

            // Update widget data
            try? updateWidgetWords()
        } catch let error as WordBankError {
            throw error
        } catch {
            errorMessage = error.localizedDescription
            throw WordBankError.deleteFailed(error.localizedDescription)
        }
    }

    // MARK: - Random Words

    /// Get random words for notifications/widgets
    func getRandomWords(count: Int) -> [WordDTO] {
        guard !words.isEmpty else { return [] }

        let shuffled = words.shuffled()
        return Array(shuffled.prefix(count))
    }

    /// Get a single random word
    func getRandomWord() -> WordDTO? {
        words.randomElement()
    }

    /// Get words that haven't been shown recently
    func getLeastRecentlyShownWords(count: Int) -> [WordDTO] {
        let sorted = words.sorted { word1, word2 in
            // Words never shown come first
            guard let date1 = word1.lastShownAt else { return true }
            guard let date2 = word2.lastShownAt else { return false }
            return date1 < date2
        }

        return Array(sorted.prefix(count))
    }

    // MARK: - Widget Support

    /// Update the words stored for widget access
    private func updateWidgetWords() throws {
        let widgetWords = getLeastRecentlyShownWords(count: 24)
        try AppGroup.save(widgetWords, forKey: AppGroup.Keys.widgetWords)
    }

    /// Load words from App Group (for widget use)
    static func loadWidgetWords() -> [WordDTO] {
        (try? AppGroup.load([WordDTO].self, forKey: AppGroup.Keys.widgetWords)) ?? []
    }
}

// MARK: - Errors

enum WordBankError: Error, LocalizedError {
    case notAuthenticated
    case fetchFailed(String)
    case addFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case wordAlreadyExists

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to access your word bank"
        case .fetchFailed(let message):
            return "Failed to fetch words: \(message)"
        case .addFailed(let message):
            return "Failed to add word: \(message)"
        case .updateFailed(let message):
            return "Failed to update word: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete word: \(message)"
        case .wordAlreadyExists:
            return "This word is already in your bank"
        }
    }
}

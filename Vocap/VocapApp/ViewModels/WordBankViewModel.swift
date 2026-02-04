import Foundation
import SwiftUI

/// ViewModel for the word bank (user's saved words)
@MainActor
final class WordBankViewModel: ObservableObject {
    // MARK: - Published State

    @Published var words: [Word] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var selectedLanguageFilter: String? = nil  // nil means "All Languages"

    // MARK: - Repository

    private let repository = WordRepository.shared

    // MARK: - Computed Properties

    /// Unique languages present in the user's word bank
    var availableLanguages: [Constants.Language] {
        let codes = Set(words.map { $0.languageCode })
        return Constants.DictionaryAPI.supportedLanguages.filter { codes.contains($0.code) }
    }

    var filteredWords: [Word] {
        var result = words

        // Filter by language if selected
        if let languageCode = selectedLanguageFilter {
            result = result.filter { $0.languageCode == languageCode }
        }

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { word in
                word.term.localizedCaseInsensitiveContains(searchText)
                    || word.definition.localizedCaseInsensitiveContains(searchText)
            }
        }

        return result
    }

    var wordCount: Int {
        words.count
    }

    var filteredWordCount: Int {
        filteredWords.count
    }

    var isEmpty: Bool {
        words.isEmpty
    }

    // MARK: - Actions

    /// Fetch all words from storage
    func fetchWords() async {
        isLoading = true
        errorMessage = nil

        do {
            try await repository.fetchAll()
            words = repository.words
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Delete a word
    func deleteWord(_ word: Word) async {
        do {
            try repository.delete(word)
            words.removeAll { $0.id == word.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Delete words at index set (for swipe to delete)
    func deleteWords(at offsets: IndexSet) async {
        for index in offsets {
            let word = filteredWords[index]
            await deleteWord(word)
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}

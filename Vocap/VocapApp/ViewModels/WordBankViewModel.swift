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

    // MARK: - Repository

    private let repository = WordRepository.shared

    // MARK: - Computed Properties

    var filteredWords: [Word] {
        if searchText.isEmpty {
            return words
        }
        return words.filter { word in
            word.term.localizedCaseInsensitiveContains(searchText)
                || word.definition.localizedCaseInsensitiveContains(searchText)
        }
    }

    var wordCount: Int {
        words.count
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

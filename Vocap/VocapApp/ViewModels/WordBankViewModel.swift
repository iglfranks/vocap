import Foundation
import SwiftUI

/// ViewModel for the word bank (user's saved words)
@MainActor
final class WordBankViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var words: [WordDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    // MARK: - Services
    
    private let wordBankService = WordBankService.shared
    
    // MARK: - Computed Properties
    
    var filteredWords: [WordDTO] {
        if searchText.isEmpty {
            return words
        }
        return words.filter { word in
            word.term.localizedCaseInsensitiveContains(searchText) ||
            word.definition.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var wordCount: Int {
        words.count
    }
    
    var isEmpty: Bool {
        words.isEmpty
    }
    
    // MARK: - Actions
    
    /// Fetch all words from the server
    func fetchWords() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await wordBankService.fetchWords()
            words = wordBankService.words
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Delete a word
    func deleteWord(_ word: WordDTO) async {
        do {
            try await wordBankService.deleteWord(id: word.id)
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


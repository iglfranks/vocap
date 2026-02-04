import Combine
import Foundation
import SwiftUI

/// ViewModel for dictionary search and adding words
@MainActor
final class SearchViewModel: ObservableObject {
    // MARK: - Published State

    @Published var searchText = "" {
        didSet {
            debouncedSearchSubject.send(searchText)
        }
    }
    @Published var searchResult: DictionaryResult?
    @Published var isSearching = false
    @Published var isAdding = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var selectedPartOfSpeech: String?
    @Published var selectedDefinition: DictionaryResult.Definition?

    // MARK: - Configuration

    @Published var language: Constants.Language

    // MARK: - Debouncing

    /// Debounce interval in milliseconds for search requests
    private static let searchDebounceMs = 300

    private let debouncedSearchSubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Services

    private let dictionaryService = DictionaryService.shared
    private let repository = WordRepository.shared

    // MARK: - Initialization

    init(language: Constants.Language = Constants.DictionaryAPI.supportedLanguages.first!) {
        self.language = language
        setupDebouncedSearch()
    }

    /// Set up debounced search to prevent rapid API requests
    private func setupDebouncedSearch() {
        debouncedSearchSubject
            .debounce(for: .milliseconds(Self.searchDebounceMs), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                // Debounced search is triggered but actual search still requires explicit call
                // This prevents accidental rapid searches during typing
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    var canSearch: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty && !isSearching
    }

    var hasResult: Bool {
        searchResult != nil
    }

    // MARK: - Rate Limiting

    /// Minimum interval between search requests (in seconds)
    private static let minSearchIntervalSeconds: TimeInterval = 0.5

    /// Timestamp of the last search request
    private var lastSearchTime: Date?

    // MARK: - Actions

    /// Search for a word definition with debouncing and rate limiting
    func search() async {
        guard canSearch else { return }

        // Rate limiting: ensure minimum interval between searches
        if let lastTime = lastSearchTime {
            let elapsed = Date().timeIntervalSince(lastTime)
            if elapsed < Self.minSearchIntervalSeconds {
                // Too soon since last search, skip
                return
            }
        }

        lastSearchTime = Date()
        isSearching = true
        errorMessage = nil
        successMessage = nil
        searchResult = nil

        do {
            let result = try await dictionaryService.lookupWord(
                searchText.trimmingCharacters(in: .whitespaces),
                language: language.code)
            searchResult = result

            // Auto-select first part of speech and first definition
            if let firstPartOfSpeech = result.allDefinitions.first?.partOfSpeech {
                selectedPartOfSpeech = firstPartOfSpeech
                selectedDefinition = result.allDefinitions.first {
                    $0.partOfSpeech == firstPartOfSpeech
                }
            }
        } catch let error as DictionaryError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to search: \(error.localizedDescription)"
        }

        isSearching = false
    }

    /// Get unique parts of speech from search result
    var partsOfSpeech: [String] {
        guard let result = searchResult else { return [] }
        return Array(Set(result.allDefinitions.map { $0.partOfSpeech })).sorted()
    }

    /// Get definitions for selected part of speech
    var definitionsForSelectedPartOfSpeech: [DictionaryResult.Definition] {
        guard let result = searchResult,
            let selectedPOS = selectedPartOfSpeech
        else {
            return []
        }
        return result.allDefinitions.filter { $0.partOfSpeech == selectedPOS }
    }

    /// Select a part of speech
    func selectPartOfSpeech(_ pos: String) {
        selectedPartOfSpeech = pos
        // Auto-select first definition for this part of speech
        if let result = searchResult {
            let definitions = result.allDefinitions.filter { $0.partOfSpeech == pos }
            selectedDefinition = definitions.first
        }
    }

    /// Select a specific definition
    func selectDefinition(_ definition: DictionaryResult.Definition) {
        selectedDefinition = definition
    }

    /// Add the selected definition to the word bank
    func addToWordBank() async {
        guard let result = searchResult,
            let selectedDef = selectedDefinition
        else { return }

        isAdding = true
        errorMessage = nil

        do {
            // Create a word from the selected definition
            let word = Word(
                term: result.word,
                definition: selectedDef.text,
                partOfSpeech: selectedDef.partOfSpeech,
                example: selectedDef.example,
                phonetic: result.phonetic,
                languageCode: language.code
            )

            try repository.save(word)
            successMessage = "'\(result.word)' (\(selectedDef.partOfSpeech)) added to your word bank!"

            // Clear search after successful add
            searchText = ""
            searchResult = nil
            selectedPartOfSpeech = nil
            selectedDefinition = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isAdding = false
    }

    /// Clear the search
    func clearSearch() {
        searchText = ""
        searchResult = nil
        selectedPartOfSpeech = nil
        selectedDefinition = nil
        errorMessage = nil
        successMessage = nil
    }

    /// Clear messages
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    /// Set the search language
    func setLanguage(_ language: Constants.Language) {
        self.language = language
        // Clear any existing search when language changes
        clearSearch()
    }
}

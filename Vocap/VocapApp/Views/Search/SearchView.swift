import SwiftUI

/// View for searching and adding new words
struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    @Environment(\.dismiss) private var dismiss

    var onWordAdded: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                    .padding()
                
                // Content
                if viewModel.isSearching {
                    Spacer()
                    ProgressView("Searching...")
                    Spacer()
                } else if let result = viewModel.searchResult {
                    searchResultView(result)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    placeholderView
                }
            }
            .navigationTitle("Add Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Added!", isPresented: .init(
                get: { viewModel.successMessage != nil },
                set: { if !$0 { 
                    viewModel.clearMessages()
                    onWordAdded?()
                    dismiss()
                }}
            )) {
                Button("OK") {
                    viewModel.clearMessages()
                    onWordAdded?()
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
        }
    }
    
    // MARK: - Search Bar

    private var searchBar: some View {
        VStack(spacing: 12) {
            // Language selector
            HStack {
                Text("Language:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Menu {
                    ForEach(Constants.DictionaryAPI.supportedLanguages) { language in
                        Button {
                            viewModel.setLanguage(language)
                        } label: {
                            HStack {
                                Text(language.name)
                                if language.code == viewModel.language.code {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.language.name)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                }

                Spacer()
            }

            // Search field
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search for a word...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await viewModel.search()
                            }
                        }

                    if !viewModel.searchText.isEmpty {
                        Button {
                            viewModel.clearSearch()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

                Button {
                    Task {
                        await viewModel.search()
                    }
                } label: {
                    Text("Search")
                        .fontWeight(.medium)
                }
                .disabled(!viewModel.canSearch)
            }
        }
    }
    
    // MARK: - Search Result View
    
    private func searchResultView(_ result: DictionaryResult) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Word header
                VStack(alignment: .leading, spacing: 8) {
                    Text(result.word.capitalized)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    
                    if let phonetic = result.phonetic {
                        Text(phonetic)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.accentColor.opacity(0.1))
                )
                
                // Parts of Speech Tabs
                if viewModel.partsOfSpeech.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(viewModel.partsOfSpeech, id: \.self) { pos in
                                Button {
                                    viewModel.selectPartOfSpeech(pos)
                                } label: {
                                    Text(pos)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(viewModel.selectedPartOfSpeech == pos ? .white : .primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            viewModel.selectedPartOfSpeech == pos
                                                ? Color.accentColor
                                                : Color(.systemGray5)
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                
                // Definitions for selected part of speech
                if !viewModel.definitionsForSelectedPartOfSpeech.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(viewModel.definitionsForSelectedPartOfSpeech.enumerated()), id: \.offset) { index, definition in
                            DefinitionCard(
                                definition: definition,
                                isSelected: viewModel.selectedDefinition?.text == definition.text,
                                onSelect: {
                                    viewModel.selectDefinition(definition)
                                }
                            )
                        }
                    }
                }
                
                // Add button
                Button {
                    Task {
                        await viewModel.addToWordBank()
                    }
                } label: {
                    HStack {
                        if viewModel.isAdding {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "plus.circle.fill")
                            if let selectedDef = viewModel.selectedDefinition {
                                Text("Add '\(result.word)' as \(selectedDef.partOfSpeech)")
                            } else {
                                Text("Add to Word Bank")
                            }
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        viewModel.selectedDefinition != nil
                            ? Color.accentColor
                            : Color.gray
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.isAdding || viewModel.selectedDefinition == nil)
                .padding(.top, 8)
            }
            .padding()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                viewModel.clearMessages()
            }
            .buttonStyle(.bordered)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Placeholder View
    
    private var placeholderView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "character.book.closed.fill")
                .font(.system(size: 64))
                .foregroundStyle(.quaternary)

            Text("Search for any \(viewModel.language.name) word")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("We'll find its definition, pronunciation,\nand example usage")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Definition Card

struct DefinitionCard: View {
    let definition: DictionaryResult.Definition
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(definition.partOfSpeech)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.accentColor.opacity(0.8))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                
                Text(definition.text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                if let example = definition.example {
                    Text("\"\(example)\"")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    SearchView()
}


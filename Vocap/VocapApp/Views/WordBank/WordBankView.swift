import SwiftUI

/// Main view showing the user's word bank
struct WordBankView: View {
    @StateObject private var viewModel = WordBankViewModel()
    @State private var showingSearch = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.isEmpty {
                    LoadingView()
                } else if viewModel.isEmpty {
                    EmptyWordBankView(onAddTapped: { showingSearch = true })
                } else {
                    wordList
                }
            }
            .navigationTitle("Word Bank")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSearch = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
                
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button {
                        editMode = editMode == .active ? .inactive : .active
                    } label: {
                        Text(editMode == .active ? "Done" : "Edit")
                    }
                }
                #endif
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showingSearch) {
                SearchView(onWordAdded: {
                    Task {
                        await viewModel.fetchWords()
                    }
                })
            }
            .refreshable {
                await viewModel.fetchWords()
            }
            .task {
                await viewModel.fetchWords()
            }
            .alert(
                "Error",
                isPresented: .init(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.clearError() } }
                )
            ) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var wordList: some View {
        List {
            // Stats header
            Section {
                HStack {
                    Label("\(viewModel.wordCount) words", systemImage: "books.vertical.fill")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }

            // Search bar
            if viewModel.wordCount > 5 {
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search your words...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                        if !viewModel.searchText.isEmpty {
                            Button {
                                viewModel.searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            // Word list
            Section {
                ForEach(viewModel.filteredWords) { word in
                    NavigationLink(destination: WordDetailView(word: word)) {
                        WordRowView(word: word)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deleteWord(word)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { indexSet in
                    Task {
                        await viewModel.deleteWords(at: indexSet)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Empty State View

struct EmptyWordBankView: View {
    let onAddTapped: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 64))
                .foregroundStyle(.quaternary)

            VStack(spacing: 8) {
                Text("Your word bank is empty")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Start building your vocabulary by\nsearching for words to add")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onAddTapped()
            } label: {
                Label("Add Your First Word", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading your words...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    WordBankView()
}

import SwiftUI

/// Detailed view of a single word
struct WordDetailView: View {
    let word: Word
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WordBankViewModel()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(word.term.capitalized)
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    HStack(spacing: 12) {
                        if let partOfSpeech = word.partOfSpeech {
                            Label(partOfSpeech, systemImage: "text.book.closed")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }

                        if let phonetic = word.phonetic, !phonetic.isEmpty {
                            Text(phonetic)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.accentColor.opacity(0.1))
                )

                // Definition
                VStack(alignment: .leading, spacing: 8) {
                    Label("Definition", systemImage: "text.quote")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(word.definition)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

                // Example (if available)
                if let example = word.example, !example.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Example", systemImage: "text.bubble")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("\"\(example)\"")
                            .font(.body)
                            .italic()
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }

                // Metadata
                VStack(alignment: .leading, spacing: 12) {
                    Label("Info", systemImage: "info.circle")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack {
                        Text("Added")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(word.addedAt.formatted(date: .abbreviated, time: .omitted))
                            .foregroundColor(.primary)
                    }
                    .font(.subheadline)

                    if let lastShown = word.lastShownAt {
                        HStack {
                            Text("Last reviewed")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(lastShown.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.primary)
                        }
                        .font(.subheadline)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Word Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .alert("Delete Word", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteWord(word)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to delete '\(word.term)'? This cannot be undone.")
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WordDetailView(
            word: Word(
                term: "serendipity",
                definition:
                    "The occurrence and development of events by chance in a happy or beneficial way.",
                partOfSpeech: "noun",
                example: "A fortunate stroke of serendipity brought them together.",
                phonetic: "/ˌserənˈdipitē/",
                addedAt: Date().addingTimeInterval(-86400 * 3),
                lastShownAt: Date().addingTimeInterval(-3600)
            ))
    }
}

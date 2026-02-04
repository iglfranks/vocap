import SwiftUI

/// A row displaying a word in the word bank list
struct WordRowView: View {
    let word: Word

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(word.term.capitalized)
                    .font(.headline)
                    .foregroundColor(.primary)

                if let partOfSpeech = word.partOfSpeech {
                    Text(partOfSpeech)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.8))
                        .clipShape(Capsule())
                }

                Spacer()

                Text(word.languageName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(word.definition)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if let phonetic = word.phonetic, !phonetic.isEmpty {
                Text(phonetic)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    List {
        WordRowView(
            word: Word(
                term: "serendipity",
                definition: "The occurrence of events by chance in a happy or beneficial way",
                partOfSpeech: "noun",
                example: "A fortunate stroke of serendipity",
                phonetic: "/ˌserənˈdipitē/",
                languageCode: "en"
            ))

        WordRowView(
            word: Word(
                term: "efímero",
                definition: "Que dura poco tiempo",
                partOfSpeech: "adjective",
                languageCode: "es"
            ))
    }
}

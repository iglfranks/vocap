//
//  VocapWidget.swift
//  VocapWidget
//
//  Word of the day widget for Vocap
//

import SwiftUI
import WidgetKit

// MARK: - Widget Word Model (matches WordDTO from main app)

struct WidgetWord: Codable, Identifiable {
    let id: UUID
    let term: String
    let definition: String
    let partOfSpeech: String?
    let phonetic: String?

    enum CodingKeys: String, CodingKey {
        case id
        case term
        case definition
        case partOfSpeech = "part_of_speech"
        case phonetic
    }

    static let placeholder = WidgetWord(
        id: UUID(),
        term: "serendipity",
        definition: "The occurrence of events by chance in a happy way",
        partOfSpeech: "noun",
        phonetic: "/ˌserənˈdipitē/"
    )

    static let empty = WidgetWord(
        id: UUID(),
        term: "Add words",
        definition: "Open Vocap to add words to your vocabulary",
        partOfSpeech: nil,
        phonetic: nil
    )
}

// MARK: - Timeline Entry

struct WordEntry: TimelineEntry {
    let date: Date
    let word: WidgetWord
    let isEmpty: Bool

    static let placeholder = WordEntry(
        date: Date(),
        word: .placeholder,
        isEmpty: false
    )

    static let empty = WordEntry(
        date: Date(),
        word: .empty,
        isEmpty: true
    )
}

// MARK: - Timeline Provider

struct WordWidgetProvider: TimelineProvider {
    private let appGroupID = "group.com.vocap.app"
    private let wordsKey = "widgetWords"

    init() {}

    func placeholder(in context: Context) -> WordEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> Void) {
        let entry = getRandomWordEntry() ?? .placeholder
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        var entries: [WordEntry] = []
        let currentDate = Date()
        let words = loadWords()

        if words.isEmpty {
            // No words - show empty state
            let entry = WordEntry(date: currentDate, word: .empty, isEmpty: true)
            let timeline = Timeline(
                entries: [entry], policy: .after(currentDate.addingTimeInterval(3600)))
            completion(timeline)
            return
        }

        // Create entries for the next 24 hours, rotating through words
        // This ensures the widget updates every hour with a different word
        for hourOffset in 0..<24 {
            let entryDate = Calendar.current.date(
                byAdding: .hour, value: hourOffset, to: currentDate)!
            let word = words[hourOffset % words.count]
            let entry = WordEntry(date: entryDate, word: word, isEmpty: false)
            entries.append(entry)
        }

        // Refresh policy: reload after 1 hour to get fresh data
        // This ensures the widget picks up new words when they're added
        let refreshDate = Calendar.current.date(
            byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }

    // MARK: - Data Loading

    private func loadWords() -> [WidgetWord] {
        guard let userDefaults = UserDefaults(suiteName: appGroupID),
            let data = userDefaults.data(forKey: wordsKey)
        else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            // Decode as WordDTO (which has all WidgetWord fields plus extras)
            struct WordDTO: Codable {
                let id: UUID
                let term: String
                let definition: String
                let partOfSpeech: String?
                let phonetic: String?

                enum CodingKeys: String, CodingKey {
                    case id
                    case term
                    case definition
                    case partOfSpeech = "part_of_speech"
                    case phonetic
                }
            }

            let dtos = try decoder.decode([WordDTO].self, from: data)
            // Convert to WidgetWord (ignoring extra fields)
            return dtos.map { dto in
                WidgetWord(
                    id: dto.id,
                    term: dto.term,
                    definition: dto.definition,
                    partOfSpeech: dto.partOfSpeech,
                    phonetic: dto.phonetic
                )
            }
        } catch {
            print("Widget: Failed to decode words: \(error)")
            return []
        }
    }

    private func getRandomWordEntry() -> WordEntry? {
        let words = loadWords()
        guard let word = words.randomElement() else { return nil }
        return WordEntry(date: Date(), word: word, isEmpty: false)
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: WordEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Word and part of speech on same line
            HStack(spacing: 6) {
                Text(entry.word.term.capitalized)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let pos = entry.word.partOfSpeech {
                    Text(pos)
                        .font(.system(size: 9))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }

            // Definition - more compact
            Text(entry.word.definition)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: WordEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Word header - compact single line
            HStack(spacing: 6) {
                Text(entry.word.term.capitalized)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let pos = entry.word.partOfSpeech {
                    Text(pos)
                        .font(.system(size: 10))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }

                if let phonetic = entry.word.phonetic {
                    Text(phonetic)
                        .font(.system(size: 11))
                        .foregroundColor(.accentColor)
                }
            }

            // Definition - full width, no line limit
            Text(entry.word.definition)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(12)
    }
}

// MARK: - Widget Entry View

struct VocapWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: WordEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            MediumWidgetView(entry: entry)  // Reuse medium for now
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Configuration

struct VocapWidget: Widget {
    let kind: String = "VocapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordWidgetProvider()) { entry in
            VocapWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(.systemBackground)
                }
        }
        .configurationDisplayName("Word of the Day")
        .description("See words from your vocabulary to keep learning.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    VocapWidget()
} timeline: {
    WordEntry.placeholder
}

#Preview("Medium", as: .systemMedium) {
    VocapWidget()
} timeline: {
    WordEntry.placeholder
}

#Preview("Empty", as: .systemSmall) {
    VocapWidget()
} timeline: {
    WordEntry.empty
}

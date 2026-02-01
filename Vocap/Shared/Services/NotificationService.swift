import Foundation
import Foundation
import SwiftData
import UserNotifications

/// Service for managing word reminder notifications
@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized = false
    @Published private(set) var pendingNotificationCount = 0

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    /// Request notification permissions
    func requestAuthorization() async throws -> Bool {
        do {
            let granted = try await center.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            isAuthorized = granted

            if granted {
                await registerNotificationCategories()
            }

            return granted
        } catch {
            throw NotificationError.authorizationFailed(error.localizedDescription)
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    /// Register custom notification categories and actions
    private func registerNotificationCategories() async {
        let showNextAction = UNNotificationAction(
            identifier: "SHOW_NEXT",
            title: "Next Word",
            options: .foreground
        )

        let markLearnedAction = UNNotificationAction(
            identifier: "MARK_LEARNED",
            title: "I Know This!",
            options: []
        )

        let wordCategory = UNNotificationCategory(
            identifier: Constants.Notifications.wordReminderCategory,
            actions: [showNextAction, markLearnedAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        center.setNotificationCategories([wordCategory])
    }

    // MARK: - Scheduling

    /// Schedule notifications based on user preferences
    func scheduleNotifications(
        for schedule: NotificationSchedule,
        words: [Word]
    ) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        guard schedule.isEnabled else {
            await cancelAllNotifications()
            return
        }

        guard !words.isEmpty else {
            throw NotificationError.noWordsToSchedule
        }

        // Cancel existing notifications first
        await cancelAllNotifications()

        // Get notification times
        let times = schedule.notificationTimesToday()
        let calendar = Calendar.current

        var scheduledCount = 0

        // Schedule for the next 7 days
        for dayOffset in 0..<7 {
            guard
                let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date())
            else {
                continue
            }

            let weekday = calendar.component(.weekday, from: targetDate) - 1  // 0-based

            guard schedule.shouldNotify(on: weekday) else {
                continue
            }

            for timeComponents in times {
                // Pick a random word for each notification
                guard let word = words.randomElement() else { continue }

                var dateComponents = calendar.dateComponents(
                    [.year, .month, .day], from: targetDate)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute

                // Skip if the time has already passed today
                if dayOffset == 0,
                    let notifDate = calendar.date(from: dateComponents),
                    notifDate < Date()
                {
                    continue
                }

                try await scheduleWordNotification(
                    word: word,
                    at: dateComponents,
                    identifier: "word_\(word.id)_\(dayOffset)_\(timeComponents.hour ?? 0)"
                )

                scheduledCount += 1
            }
        }

        pendingNotificationCount = scheduledCount
    }

    /// Schedule a single word notification
    private func scheduleWordNotification(
        word: Word,
        at dateComponents: DateComponents,
        identifier: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = word.term.capitalized
        content.body = word.definition
        content.sound = .default
        content.categoryIdentifier = Constants.Notifications.wordReminderCategory

        // Add word data for handling actions
        content.userInfo = [
            "wordId": word.id.hashValue.description,
            "term": word.term,
        ]

        // Add subtitle with part of speech if available
        if let partOfSpeech = word.partOfSpeech {
            content.subtitle = partOfSpeech
        }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    /// Schedule a test notification (for debugging)
    func scheduleTestNotification(word: Word, inSeconds seconds: TimeInterval = 5) async throws {
        guard isAuthorized else {
            throw NotificationError.notAuthorized
        }

        let content = UNMutableNotificationContent()
        content.title = word.term.capitalized
        content.body = word.definition
        content.sound = .default
        content.categoryIdentifier = Constants.Notifications.wordReminderCategory

        if let partOfSpeech = word.partOfSpeech {
            content.subtitle = partOfSpeech
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: seconds,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "test_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Management

    /// Cancel all pending notifications
    func cancelAllNotifications() async {
        center.removeAllPendingNotificationRequests()
        pendingNotificationCount = 0
    }

    /// Cancel notifications for a specific word
    func cancelNotifications(for wordId: PersistentIdentifier) async {
        let wordIdString = wordId.hashValue.description
        let pending = await center.pendingNotificationRequests()
        let toRemove =
            pending
            .filter { $0.identifier.contains(wordIdString) }
            .map { $0.identifier }

        center.removePendingNotificationRequests(withIdentifiers: toRemove)

        // Update count
        pendingNotificationCount = max(0, pendingNotificationCount - toRemove.count)
    }

    /// Get count of pending notifications
    func getPendingCount() async -> Int {
        let pending = await center.pendingNotificationRequests()
        pendingNotificationCount = pending.count
        return pending.count
    }
}

// MARK: - Errors

enum NotificationError: Error, LocalizedError {
    case notAuthorized
    case authorizationFailed(String)
    case schedulingFailed(String)
    case noWordsToSchedule

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Notifications are not authorized. Please enable them in Settings."
        case .authorizationFailed(let message):
            return "Failed to authorize notifications: \(message)"
        case .schedulingFailed(let message):
            return "Failed to schedule notification: \(message)"
        case .noWordsToSchedule:
            return "Add some words to your bank first!"
        }
    }
}

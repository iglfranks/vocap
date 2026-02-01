import Foundation
import SwiftData

/// Repository for local notification schedule storage
/// Uses the shared ModelContainer from WordRepository for CloudKit sync
@MainActor
final class NotificationScheduleRepository {
    static let shared = NotificationScheduleRepository()

    private var modelContext: ModelContext {
        WordRepository.shared.modelContainer.mainContext
    }

    private init() {}

    // MARK: - CRUD Operations

    /// Get the current notification schedule (there should only be one)
    func getCurrent() throws -> NotificationSchedule? {
        var descriptor = FetchDescriptor<NotificationSchedule>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    /// Save or update the notification schedule
    func save(_ schedule: NotificationSchedule) throws {
        // Delete any existing schedules first
        try modelContext.delete(model: NotificationSchedule.self)

        // Insert the new one
        modelContext.insert(schedule)
        try modelContext.save()
    }

    /// Create default notification schedule if none exists
    func getOrCreateDefault() throws -> NotificationSchedule {
        if let existing = try getCurrent() {
            return existing
        }

        let defaultSchedule = NotificationSchedule()
        try save(defaultSchedule)
        return defaultSchedule
    }

    /// Delete the notification schedule
    func delete() throws {
        try modelContext.delete(model: NotificationSchedule.self)
        try modelContext.save()
    }
}

import Foundation
import SwiftData

/// Repository for local notification schedule storage
@MainActor
final class NotificationScheduleRepository {
    static let shared = NotificationScheduleRepository()
    
    private var modelContainer: ModelContainer?
    private var modelContext: ModelContext?
    
    private init() {
        setupContainer()
    }
    
    /// Set up the SwiftData container
    private func setupContainer() {
        do {
            let schema = Schema([Word.self, NotificationSchedule.self])
            
            var configuration: ModelConfiguration
            
            if let appGroupURL = AppGroup.swiftDataURL {
                configuration = ModelConfiguration(
                    schema: schema,
                    url: appGroupURL,
                    allowsSave: true
                )
            } else {
                configuration = ModelConfiguration(schema: schema)
            }
            
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContext = modelContainer?.mainContext
            
        } catch {
            print("Failed to create ModelContainer: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Get the current notification schedule (there should only be one)
    func getCurrent() throws -> NotificationSchedule? {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }
        
        var descriptor = FetchDescriptor<NotificationSchedule>()
        descriptor.fetchLimit = 1
        
        return try context.fetch(descriptor).first
    }
    
    /// Save or update the notification schedule
    func save(_ schedule: NotificationSchedule) throws {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }
        
        // Delete any existing schedules first
        try context.delete(model: NotificationSchedule.self)
        
        // Insert the new one
        context.insert(schedule)
        try context.save()
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
    
    /// Update schedule from DTO (after sync)
    func updateFromDTO(_ dto: NotificationScheduleDTO) throws {
        let schedule = dto.toModel()
        try save(schedule)
    }
    
    /// Delete the notification schedule
    func delete() throws {
        guard let context = modelContext else {
            throw RepositoryError.contextNotAvailable
        }
        
        try context.delete(model: NotificationSchedule.self)
        try context.save()
    }
}


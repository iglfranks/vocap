import Foundation
import SwiftData

/// Represents the user's notification preferences
@Model
final class NotificationSchedule {
    /// Unique identifier
    @Attribute(.unique) var id: UUID
    
    /// Whether notifications are enabled
    var isEnabled: Bool
    
    /// Hours between notifications (e.g., 4 = every 4 hours)
    var frequencyHours: Int
    
    /// Earliest hour to send notifications (0-23)
    var startHour: Int
    
    /// Latest hour to send notifications (0-23)
    var endHour: Int
    
    /// Days of the week to send notifications (0 = Sunday, 6 = Saturday)
    /// If empty, notifications are sent every day
    var activeDays: [Int]
    
    /// Remote ID from Supabase (for sync)
    var remoteUserId: UUID?
    
    /// Whether this schedule has been synced to the server
    var isSynced: Bool
    
    init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        frequencyHours: Int = 4,
        startHour: Int = 9,
        endHour: Int = 21,
        activeDays: [Int] = [0, 1, 2, 3, 4, 5, 6],
        remoteUserId: UUID? = nil,
        isSynced: Bool = false
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.frequencyHours = frequencyHours
        self.startHour = startHour
        self.endHour = endHour
        self.activeDays = activeDays
        self.remoteUserId = remoteUserId
        self.isSynced = isSynced
    }
    
    /// Get the next notification times for today
    func notificationTimesToday() -> [DateComponents] {
        var times: [DateComponents] = []
        var currentHour = startHour
        
        while currentHour <= endHour {
            var components = DateComponents()
            components.hour = currentHour
            components.minute = 0
            times.append(components)
            currentHour += frequencyHours
        }
        
        return times
    }
    
    /// Check if notifications should be sent on a given day
    func shouldNotify(on weekday: Int) -> Bool {
        activeDays.isEmpty || activeDays.contains(weekday)
    }
}

// MARK: - DTO for API/Supabase communication

/// Data transfer object for NotificationSchedule
struct NotificationScheduleDTO: Codable, Sendable {
    let userId: UUID
    let enabled: Bool
    let frequencyHours: Int
    let startHour: Int
    let endHour: Int
    let activeDays: [Int]?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case enabled
        case frequencyHours = "frequency_hours"
        case startHour = "start_hour"
        case endHour = "end_hour"
        case activeDays = "active_days"
    }
    
    func toModel() -> NotificationSchedule {
        NotificationSchedule(
            isEnabled: enabled,
            frequencyHours: frequencyHours,
            startHour: startHour,
            endHour: endHour,
            activeDays: activeDays ?? [0, 1, 2, 3, 4, 5, 6],
            remoteUserId: userId,
            isSynced: true
        )
    }
}

extension NotificationSchedule {
    func toDTO(userId: UUID) -> NotificationScheduleDTO {
        NotificationScheduleDTO(
            userId: userId,
            enabled: isEnabled,
            frequencyHours: frequencyHours,
            startHour: startHour,
            endHour: endHour,
            activeDays: activeDays
        )
    }
}


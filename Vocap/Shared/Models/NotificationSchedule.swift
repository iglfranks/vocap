import Foundation
import SwiftData

/// Represents the user's notification preferences
@Model
final class NotificationSchedule {
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
    /// Stored as JSON string because SwiftData has issues with primitive arrays
    private var activeDaysData: String = "[0,1,2,3,4,5,6]"

    /// Computed property to access days as [Int]
    var activeDays: [Int] {
        get {
            guard let data = activeDaysData.data(using: .utf8),
                  let days = try? JSONDecoder().decode([Int].self, from: data) else {
                return []
            }
            return days
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let string = String(data: data, encoding: .utf8) {
                activeDaysData = string
            }
        }
    }

    init(
        isEnabled: Bool = true,
        frequencyHours: Int = 4,
        startHour: Int = 9,
        endHour: Int = 21,
        activeDays: [Int] = [0, 1, 2, 3, 4, 5, 6]
    ) {
        self.isEnabled = isEnabled
        self.frequencyHours = frequencyHours
        self.startHour = startHour
        self.endHour = endHour
        // Encode activeDays as JSON string for SwiftData compatibility
        if let data = try? JSONEncoder().encode(activeDays),
           let string = String(data: data, encoding: .utf8) {
            self.activeDaysData = string
        } else {
            self.activeDaysData = "[]"
        }
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

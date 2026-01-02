import Foundation

extension Date {
    /// Format date for display
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Relative time string (e.g., "2 hours ago")
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Check if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Check if date is in the past
    var isPast: Bool {
        self < Date()
    }
    
    /// Get the hour component (0-23)
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }
    
    /// Get the weekday (0 = Sunday, 6 = Saturday)
    var weekday: Int {
        Calendar.current.component(.weekday, from: self) - 1
    }
    
    /// Start of the day
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// End of the day
    var endOfDay: Date {
        Calendar.current.date(byAdding: DateComponents(day: 1, second: -1), to: startOfDay) ?? self
    }
}


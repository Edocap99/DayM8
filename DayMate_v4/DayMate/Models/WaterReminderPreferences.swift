import Foundation

/// User-selected reminder configuration. The daily window is 09:00–21:00.
struct WaterReminderPreferences: Codable, Equatable {
    var enabled: Bool
    var intervalHours: Int

    static let `default` = WaterReminderPreferences(enabled: false, intervalHours: 2)

    var reminderHours: [Int] {
        Array(stride(from: 9, through: 21, by: max(1, min(4, intervalHours))))
    }
}

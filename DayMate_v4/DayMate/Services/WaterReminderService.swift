import Foundation
import UserNotifications

/// Owns iOS local notification authorization and the scheduled water alerts.
/// Does not contain any UI or business state.
struct WaterReminderService {
    private let center = UNUserNotificationCenter.current()
    private static let ids = (0...23).map { "daymate.water.\($0)" }

    /// Returns false if permission was not granted; throws for scheduling failures.
    func configure(enabled: Bool, intervalHours: Int) async throws -> Bool {
        if !enabled {
            center.removePendingNotificationRequests(withIdentifiers: Self.ids)
            center.removeDeliveredNotifications(withIdentifiers: Self.ids)
            return true
        }

        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        guard granted else { return false }

        // Remove only our own requests; never touch other app notifications.
        center.removePendingNotificationRequests(withIdentifiers: Self.ids)
        let preferences = WaterReminderPreferences(enabled: true, intervalHours: intervalHours)
        do {
            for hour in preferences.reminderHours {
                let content = UNMutableNotificationContent()
                content.title = "Time for some water"
                content.body = "Take a little sip and track it in DayMate."
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: DateComponents(hour: hour, minute: 0),
                    repeats: true
                )
                let request = UNNotificationRequest(
                    identifier: "daymate.water.\(hour)",
                    content: content,
                    trigger: trigger
                )
                try await center.add(request)
            }
            return true
        } catch {
            center.removePendingNotificationRequests(withIdentifiers: Self.ids)
            throw error
        }
    }
}


// MARK: - One-time planner activity notifications

/// Separate notification identifiers keep activity reminders independent of Water.
/// This service is intentionally in the existing Services file, so you do not
/// need to add a new file to the Xcode app target.
struct ActivityReminderService {
    private let center = UNUserNotificationCenter.current()
    private static let prefix = "daymate.activity."

    static func identifier(for id: UUID) -> String {
        prefix + id.uuidString
    }

    /// Request permission only when the user has chosen to receive reminders.
    /// Already granted permissions (including those granted for Water) are reused.
    func requestPermission() async throws -> Bool {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return try await center.requestAuthorization(options: [.alert, .sound])
        @unknown default:
            return false
        }
    }

    /// One alert at the exact date and local clock time, without repetition.
    /// Does NOT remove or modify water notifications.
    func schedule(_ task: DayTask) async throws {
        guard task.hasStartReminder,
              !task.isCompleted,
              task.scheduledAt > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "DayMate · Time for your activity"
        content.body = "\(task.title) is scheduled for now. One tiny step at a time!"
        content.sound = .default

        var components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: task.scheduledAt
        )
        components.calendar = Calendar.current
        components.timeZone = TimeZone.current

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: Self.identifier(for: task.id),
            content: content,
            trigger: trigger
        )
        try await center.add(request)
    }

    /// Remove only the selected activity's pending / delivered alert.
    func cancel(id: UUID) {
        let ids = [Self.identifier(for: id)]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    /// Repairs pending alerts when the app is relaunched or becomes active.
    /// Never requests permission automatically and leaves Water alerts intact.
    func reconcile(with tasks: [DayTask]) async {
        let eligible = tasks.filter { task in
            task.hasStartReminder && !task.isCompleted && task.scheduledAt > Date()
        }
        let desired = Set(eligible.map { Self.identifier(for: $0.id) })
        let pending = await center.pendingNotificationRequests()
        let existing = Set(
            pending.map(\.identifier).filter { $0.hasPrefix(Self.prefix) }
        )
        let obsolete = existing.subtracting(desired)
        if !obsolete.isEmpty {
            center.removePendingNotificationRequests(
                withIdentifiers: Array(obsolete)
            )
        }

        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        default:
            return
        }

        for task in eligible where !existing.contains(Self.identifier(for: task.id)) {
            do {
                try await schedule(task)
            } catch {
                // A temporary notification scheduling failure must not affect
                // the activity data. A subsequent foreground pass can retry.
                print("DayMate activity reminder: \(error.localizedDescription)")
            }
        }
    }
}


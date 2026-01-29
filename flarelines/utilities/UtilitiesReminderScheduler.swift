// ABOUTME: Schedules and cancels daily reminder notifications.
// ABOUTME: Uses UNUserNotificationCenter to create repeating daily notifications at user-specified time.

import Foundation
import UserNotifications

@MainActor
final class ReminderScheduler {
    static let shared = ReminderScheduler()

    private let notificationCenter = UNUserNotificationCenter.current()
    private let reminderIdentifier = "daily-reminder"

    private init() {}

    /// Schedules a daily reminder notification at the specified time.
    /// Cancels any existing reminder before scheduling the new one.
    /// - Parameter time: The time of day to show the reminder
    func scheduleDaily(at time: Date) async {
        // Cancel existing reminder first
        await cancelReminder()

        // Extract hour and minute from the time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time to journal")
        content.body = String(localized: "How are you feeling today?")
        content.sound = .default

        // Create a daily repeating trigger
        var triggerComponents = DateComponents()
        triggerComponents.hour = components.hour
        triggerComponents.minute = components.minute

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerComponents,
            repeats: true
        )

        // Create and add the request
        let request = UNNotificationRequest(
            identifier: reminderIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule reminder: \(error.localizedDescription)")
        }
    }

    /// Cancels any existing daily reminder notification.
    func cancelReminder() async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [reminderIdentifier]
        )
    }

    /// Checks if a daily reminder is currently scheduled.
    /// - Returns: True if a reminder is scheduled
    func isReminderScheduled() async -> Bool {
        let requests = await notificationCenter.pendingNotificationRequests()
        return requests.contains { $0.identifier == reminderIdentifier }
    }
}

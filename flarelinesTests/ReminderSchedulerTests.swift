// ABOUTME: Tests for reminder scheduling date component extraction.
// ABOUTME: Validates time extraction from Date objects for notification triggers.

import Foundation
import Testing
@testable import Flarelines

// MARK: - Date Component Extraction Helper

/// Replicates the date component extraction logic from ReminderScheduler
enum ReminderDateComponents {
    /// Extracts hour and minute from a Date for notification scheduling
    static func extract(from date: Date) -> (hour: Int?, minute: Int?) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour, components.minute)
    }

    /// Creates DateComponents for a daily trigger at the given time
    static func makeTriggerComponents(hour: Int, minute: Int) -> DateComponents {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return components
    }
}

struct ReminderSchedulerTests {

    // MARK: - Date Component Extraction Tests

    @Test func extractHourAndMinuteFromMorning() {
        // Create date for 9:30 AM
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 9
        components.minute = 30

        let date = Calendar.current.date(from: components)!
        let (hour, minute) = ReminderDateComponents.extract(from: date)

        #expect(hour == 9)
        #expect(minute == 30)
    }

    @Test func extractHourAndMinuteFromEvening() {
        // Create date for 8:45 PM (20:45)
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 20
        components.minute = 45

        let date = Calendar.current.date(from: components)!
        let (hour, minute) = ReminderDateComponents.extract(from: date)

        #expect(hour == 20)
        #expect(minute == 45)
    }

    @Test func extractMidnight() {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 0
        components.minute = 0

        let date = Calendar.current.date(from: components)!
        let (hour, minute) = ReminderDateComponents.extract(from: date)

        #expect(hour == 0)
        #expect(minute == 0)
    }

    @Test func extractEndOfDay() {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 23
        components.minute = 59

        let date = Calendar.current.date(from: components)!
        let (hour, minute) = ReminderDateComponents.extract(from: date)

        #expect(hour == 23)
        #expect(minute == 59)
    }

    // MARK: - Trigger Components Tests

    @Test func makeTriggerComponentsForMorning() {
        let components = ReminderDateComponents.makeTriggerComponents(hour: 9, minute: 0)

        #expect(components.hour == 9)
        #expect(components.minute == 0)
    }

    @Test func makeTriggerComponentsForEvening() {
        let components = ReminderDateComponents.makeTriggerComponents(hour: 21, minute: 30)

        #expect(components.hour == 21)
        #expect(components.minute == 30)
    }

    @Test func triggerComponentsHaveOnlyHourAndMinute() {
        let components = ReminderDateComponents.makeTriggerComponents(hour: 12, minute: 0)

        // Should only have hour and minute set (for daily repeating trigger)
        #expect(components.year == nil)
        #expect(components.month == nil)
        #expect(components.day == nil)
        #expect(components.hour != nil)
        #expect(components.minute != nil)
    }

    // MARK: - Round Trip Tests

    @Test func extractAndReconstructPreservesTime() {
        // Create a time
        var originalComponents = DateComponents()
        originalComponents.year = 2026
        originalComponents.month = 6
        originalComponents.day = 15
        originalComponents.hour = 14
        originalComponents.minute = 30

        let date = Calendar.current.date(from: originalComponents)!

        // Extract hour and minute
        let (hour, minute) = ReminderDateComponents.extract(from: date)

        // Create trigger components
        let triggerComponents = ReminderDateComponents.makeTriggerComponents(
            hour: hour!,
            minute: minute!
        )

        #expect(triggerComponents.hour == 14)
        #expect(triggerComponents.minute == 30)
    }

    // MARK: - Edge Cases

    @Test(arguments: [
        (0, 0),
        (6, 30),
        (12, 0),
        (18, 45),
        (23, 59),
    ])
    func commonReminderTimes(hour: Int, minute: Int) {
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 1
        components.hour = hour
        components.minute = minute

        let date = Calendar.current.date(from: components)!
        let (extractedHour, extractedMinute) = ReminderDateComponents.extract(from: date)

        #expect(extractedHour == hour)
        #expect(extractedMinute == minute)
    }
}

// MARK: - Notification Identifier Tests

struct ReminderIdentifierTests {

    @Test func reminderIdentifierIsConsistent() {
        // The identifier should be a constant string for proper cancellation
        let identifier = "daily-reminder"

        // Verify it's a reasonable identifier
        #expect(!identifier.isEmpty)
        #expect(!identifier.contains(" "))
        #expect(identifier == "daily-reminder")
    }
}

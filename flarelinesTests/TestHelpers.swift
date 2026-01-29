// ABOUTME: Shared test utilities and mock objects for unit testing.
// ABOUTME: Provides in-memory Core Data contexts and test fixtures.

import Foundation
import CoreData
@testable import Flarelines

// MARK: - In-Memory Core Data Context

enum TestCoreData {
    /// Shared in-memory persistence controller for all tests
    /// Using a singleton prevents multiple NSManagedObjectModel registrations
    private static let sharedController = PersistenceController(inMemory: true)

    /// Creates an in-memory Core Data context for testing
    /// Returns a fresh child context to isolate test data
    static func makeInMemoryContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = sharedController.container.viewContext
        return context
    }

    /// Creates a context with sample data pre-populated
    static func makeContextWithSampleData(entryCount: Int = 10) -> NSManagedObjectContext {
        let context = makeInMemoryContext()
        let calendar = Calendar.current

        for i in 0..<entryCount {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.timestamp = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            entry.journalText = "Sample entry \(i)"
            entry.userScore = Int16(i % 4)
            entry.mlScore = Int16(i % 4)
        }

        try? context.save()
        return context
    }
}

// MARK: - Test Entry Factory

enum TestEntryFactory {
    /// Creates a JournalEntry with default values
    static func makeEntry(
        context: NSManagedObjectContext,
        text: String? = "Test entry",
        userScore: Int16 = 1,
        mlScore: Int16 = 1,
        daysAgo: Int = 0
    ) -> JournalEntry {
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.timestamp = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        entry.journalText = text
        entry.userScore = userScore
        entry.mlScore = mlScore
        return entry
    }

    /// Creates multiple entries with sequential dates
    static func makeEntries(
        context: NSManagedObjectContext,
        count: Int,
        startingDaysAgo: Int = 0
    ) -> [JournalEntry] {
        (0..<count).map { i in
            makeEntry(context: context, text: "Entry \(i)", daysAgo: startingDaysAgo + i)
        }
    }
}

// MARK: - Date Test Helpers

enum TestDates {
    static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Creates a date from ISO8601 string
    static func date(from string: String) -> Date {
        formatter.date(from: string) ?? Date()
    }

    /// Creates a date relative to now
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }

    /// Creates a date relative to now
    static func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
    }

    /// Start of today
    static var startOfToday: Date {
        Calendar.current.startOfDay(for: Date())
    }
}

// MARK: - Mock Model Info Factory

enum TestModelInfo {
    static func make(
        id: String = "test-model",
        version: String = "1.0.0",
        filename: String = "test.gguf",
        sizeBytes: Int64 = 500_000_000,
        sha256: String = "abc123def456",
        minAppVersion: String = "1.0.0",
        downloadUrl: String = "https://example.com/test.gguf"
    ) -> ModelInfo {
        ModelInfo(
            id: id,
            version: version,
            filename: filename,
            sizeBytes: sizeBytes,
            sha256: sha256,
            minAppVersion: minAppVersion,
            downloadUrl: downloadUrl
        )
    }
}

// MARK: - CSV Test Entry

/// Test struct conforming to CSVExportable for isolated CSV testing
struct TestCSVEntry: CSVExportable {
    var timestamp: Date
    var journalText: String?
    var userScore: Int16
    var mlScore: Int16

    static func make(
        timestamp: Date = Date(),
        text: String? = "Test",
        userScore: Int16 = 1,
        mlScore: Int16 = 1
    ) -> TestCSVEntry {
        TestCSVEntry(
            timestamp: timestamp,
            journalText: text,
            userScore: userScore,
            mlScore: mlScore
        )
    }
}

// MARK: - Assertion Helpers

enum TestAssertions {
    /// Checks if a date is within a certain number of seconds of another date
    static func isClose(_ date1: Date, to date2: Date, within seconds: TimeInterval = 1) -> Bool {
        abs(date1.timeIntervalSince(date2)) <= seconds
    }

    /// Checks if a value is within a range
    static func isInRange<T: Comparable>(_ value: T, min: T, max: T) -> Bool {
        value >= min && value <= max
    }
}

// ABOUTME: Integration tests for Core Data persistence layer.
// ABOUTME: Uses in-memory store for isolated, fast test execution.

import Foundation
import Testing
import CoreData
@testable import Flarelines

struct CoreDataTests {

    // MARK: - Helper to create in-memory context

    private func makeInMemoryContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "flarelines")
        container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }

        return container.viewContext
    }

    private func fetchAllEntries(_ context: NSManagedObjectContext) throws -> [JournalEntry] {
        let fetchRequest = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        return try context.fetch(fetchRequest)
    }

    // MARK: - JournalEntry CRUD Tests

    @Test func createJournalEntry() throws {
        let context = makeInMemoryContext()

        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.journalText = "Test diary entry"
        entry.userScore = 1
        entry.mlScore = -1

        try context.save()

        let results = try fetchAllEntries(context)

        #expect(results.count == 1)
        #expect(results.first?.journalText == "Test diary entry")
        #expect(results.first?.userScore == 1)
        #expect(results.first?.mlScore == -1)
    }

    @Test func updateJournalEntry() throws {
        let context = makeInMemoryContext()

        // Create entry
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.journalText = "Original text"
        entry.userScore = 0
        entry.mlScore = -1

        try context.save()

        // Update entry
        entry.journalText = "Updated text"
        entry.userScore = 2
        entry.mlScore = 2

        try context.save()

        // Fetch and verify
        let results = try fetchAllEntries(context)

        #expect(results.count == 1)
        #expect(results.first?.journalText == "Updated text")
        #expect(results.first?.userScore == 2)
        #expect(results.first?.mlScore == 2)
    }

    @Test func deleteJournalEntry() throws {
        let context = makeInMemoryContext()

        // Create entry
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.journalText = "To be deleted"
        entry.userScore = 1
        entry.mlScore = 1

        try context.save()

        // Delete entry
        context.delete(entry)
        try context.save()

        // Verify deletion
        let results = try fetchAllEntries(context)

        #expect(results.isEmpty)
    }

    @Test func createMultipleEntries() throws {
        let context = makeInMemoryContext()
        let calendar = Calendar.current

        // Create 5 entries
        for i in 0..<5 {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.timestamp = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            entry.journalText = "Entry \(i)"
            entry.userScore = Int16(i % 4)
            entry.mlScore = Int16(i % 4)
        }

        try context.save()

        let results = try fetchAllEntries(context)

        #expect(results.count == 5)
    }

    // MARK: - Fetch Request Tests

    @Test func fetchEntriesSortedByDate() throws {
        let context = makeInMemoryContext()
        let calendar = Calendar.current

        // Create entries with different dates
        let dates = [
            calendar.date(byAdding: .day, value: -2, to: Date())!,
            calendar.date(byAdding: .day, value: 0, to: Date())!,
            calendar.date(byAdding: .day, value: -5, to: Date())!,
        ]

        for (index, date) in dates.enumerated() {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.timestamp = date
            entry.journalText = "Entry \(index)"
            entry.userScore = 1
            entry.mlScore = 1
        }

        try context.save()

        // Fetch sorted by timestamp descending (newest first)
        let fetchRequest = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]

        let results = try context.fetch(fetchRequest)

        #expect(results.count == 3)
        #expect(results[0].timestamp >= results[1].timestamp)
        #expect(results[1].timestamp >= results[2].timestamp)
    }

    @Test func fetchEntriesWithPredicate() throws {
        let context = makeInMemoryContext()

        // Create entries with different scores
        for score in 0...3 {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.timestamp = Date()
            entry.journalText = "Score \(score)"
            entry.userScore = Int16(score)
            entry.mlScore = Int16(score)
        }

        try context.save()

        // Fetch only severe entries (score = 3)
        let fetchRequest = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(format: "userScore == %d", 3)

        let results = try context.fetch(fetchRequest)

        #expect(results.count == 1)
        #expect(results.first?.userScore == 3)
    }

    @Test func fetchEntriesInDateRange() throws {
        let context = makeInMemoryContext()
        let calendar = Calendar.current
        let now = Date()

        // Create entries: 2 within last 7 days, 2 older
        let recentDates = [
            calendar.date(byAdding: .day, value: -1, to: now)!,
            calendar.date(byAdding: .day, value: -5, to: now)!,
        ]

        let olderDates = [
            calendar.date(byAdding: .day, value: -10, to: now)!,
            calendar.date(byAdding: .day, value: -30, to: now)!,
        ]

        for date in recentDates + olderDates {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.timestamp = date
            entry.journalText = "Entry"
            entry.userScore = 1
            entry.mlScore = 1
        }

        try context.save()

        // Fetch entries from last 7 days
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let fetchRequest = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        fetchRequest.predicate = NSPredicate(format: "timestamp >= %@", sevenDaysAgo as NSDate)

        let results = try context.fetch(fetchRequest)

        #expect(results.count == 2)
    }

    // MARK: - Score Validation Tests

    @Test func entryAcceptsValidUserScores() throws {
        let context = makeInMemoryContext()

        for score in 0...3 {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.timestamp = Date()
            entry.journalText = "Test"
            entry.userScore = Int16(score)
            entry.mlScore = Int16(score)
        }

        try context.save()

        let results = try fetchAllEntries(context)

        #expect(results.count == 4)
    }

    @Test func entryAcceptsNegativeOneMLScore() throws {
        let context = makeInMemoryContext()

        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.journalText = "Not scored yet"
        entry.userScore = 1
        entry.mlScore = -1  // Indicates not scored

        try context.save()

        let results = try fetchAllEntries(context)

        #expect(results.first?.mlScore == -1)
    }

    // MARK: - Nil Text Handling

    @Test func entryAllowsNilJournalText() throws {
        let context = makeInMemoryContext()

        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.journalText = nil
        entry.userScore = 0
        entry.mlScore = -1

        try context.save()

        let results = try fetchAllEntries(context)

        #expect(results.first?.journalText == nil)
    }

    // MARK: - UUID Uniqueness

    @Test func entriesHaveUniqueIds() throws {
        let context = makeInMemoryContext()

        var ids: Set<UUID> = []

        for _ in 0..<10 {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.timestamp = Date()
            entry.userScore = 1
            entry.mlScore = 1

            ids.insert(entry.id)
        }

        try context.save()

        #expect(ids.count == 10)
    }
}

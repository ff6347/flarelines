// ABOUTME: Tests for SampleDataGenerator functionality.
// ABOUTME: Validates sample data creation and clearing operations.

import Foundation
import Testing
import CoreData
@testable import Flarelines

struct SampleDataGeneratorTests {

    // MARK: - Helper

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

    private func fetchEntryCount(_ context: NSManagedObjectContext) throws -> Int {
        return try fetchAllEntries(context).count
    }

    // MARK: - Generation Tests

    @Test func generateSampleEntriesCreatesCorrectCount() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateSampleEntries(context: context, count: 10)

        let count = try fetchEntryCount(context)
        #expect(count == 10)
    }

    @Test func generateWeekOfEntriesCreatesSevenEntries() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateWeekOfEntries(context: context)

        let count = try fetchEntryCount(context)
        #expect(count == 7)
    }

    @Test func generateMonthOfEntriesCreatesThirtyEntries() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateMonthOfEntries(context: context)

        let count = try fetchEntryCount(context)
        #expect(count == 30)
    }

    @Test func generateYearOfEntriesCreates365Entries() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateYearOfEntries(context: context)

        let count = try fetchEntryCount(context)
        #expect(count == 365)
    }

    // MARK: - Entry Content Tests

    @Test func generatedEntriesHaveValidScores() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateSampleEntries(context: context, count: 50)

        let entries = try fetchAllEntries(context)

        for entry in entries {
            #expect(entry.userScore >= 0 && entry.userScore <= 3,
                    "userScore \(entry.userScore) out of range")
            #expect(entry.mlScore >= -1 && entry.mlScore <= 3,
                    "mlScore \(entry.mlScore) out of range")
        }
    }

    @Test func generatedEntriesHaveUniqueIds() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateSampleEntries(context: context, count: 20)

        let entries = try fetchAllEntries(context)

        let ids = Set(entries.map { $0.id })
        #expect(ids.count == 20)
    }

    @Test func generatedEntriesHaveSequentialDates() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateSampleEntries(context: context, count: 10)

        let fetchRequest = NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.timestamp, ascending: false)]
        let entries = try context.fetch(fetchRequest)

        // First entry should be most recent (today or yesterday)
        let now = Date()
        let dayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        #expect(entries[0].timestamp >= dayAgo)

        // Each subsequent entry should be older
        for i in 0..<(entries.count - 1) {
            #expect(entries[i].timestamp >= entries[i + 1].timestamp)
        }
    }

    @Test func generatedEntriesHaveJournalText() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateSampleEntries(context: context, count: 20)

        let entries = try fetchAllEntries(context)

        for entry in entries {
            #expect(entry.journalText != nil)
            #expect(!entry.journalText!.isEmpty)
        }
    }

    @Test func generatedEntriesHaveGermanText() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateSampleEntries(context: context, count: 30)

        let entries = try fetchAllEntries(context)

        // At least some entries should contain German words
        let germanWords = ["heute", "gut", "Schmerzen", "Müdigkeit", "Tag", "Arzt", "Symptome"]
        var foundGerman = false

        for entry in entries {
            if let text = entry.journalText?.lowercased() {
                if germanWords.contains(where: { text.contains($0.lowercased()) }) {
                    foundGerman = true
                    break
                }
            }
        }

        #expect(foundGerman, "Expected at least some German text in generated entries")
    }

    // MARK: - Clear Data Tests

    @Test func clearAllDataRemovesAllEntries() throws {
        let context = makeInMemoryContext()

        // Generate some data
        SampleDataGenerator.generateSampleEntries(context: context, count: 20)

        var count = try fetchEntryCount(context)
        #expect(count == 20)

        // Clear all data
        SampleDataGenerator.clearAllData(context: context)

        // Refetch - need to reset context to see batch delete results
        context.reset()
        count = try fetchEntryCount(context)
        #expect(count == 0)
    }

    @Test func clearAllDataOnEmptyContextSucceeds() throws {
        let context = makeInMemoryContext()

        // Should not throw on empty context
        SampleDataGenerator.clearAllData(context: context)

        let count = try fetchEntryCount(context)
        #expect(count == 0)
    }

    // MARK: - Score Distribution Tests

    @Test func generatedEntriesHaveVariedScores() throws {
        let context = makeInMemoryContext()

        // Generate enough entries to likely have score variety
        SampleDataGenerator.generateSampleEntries(context: context, count: 100)

        let entries = try fetchAllEntries(context)

        let uniqueUserScores = Set(entries.map { $0.userScore })

        // With 100 entries, we should have at least 2 different scores
        #expect(uniqueUserScores.count >= 2,
                "Expected varied scores, got only: \(uniqueUserScores)")
    }

    @Test func someEntriesHaveUnscoredMLScore() throws {
        let context = makeInMemoryContext()

        SampleDataGenerator.generateSampleEntries(context: context, count: 50)

        let entries = try fetchAllEntries(context)

        // Some entries should have mlScore = -1 (not scored)
        let unscoredCount = entries.filter { $0.mlScore == -1 }.count

        #expect(unscoredCount > 0,
                "Expected some entries with mlScore = -1 (not scored)")
    }
}

// ABOUTME: Tests for CSV export functionality.
// ABOUTME: Validates CSV format with timestamp, journalText, userScore, mlScore.

import Foundation
import Testing
@testable import Flarelines

/// Test struct that conforms to CSVExportable for isolated testing.
struct TestEntry: CSVExportable {
    var timestamp: Date
    var journalText: String?
    var userScore: Int16
    var mlScore: Int16
}

struct CSVExporterTests {

    private func makeEntry(
        timestamp: Date,
        text: String?,
        userScore: Int16,
        mlScore: Int16
    ) -> TestEntry {
        TestEntry(
            timestamp: timestamp,
            journalText: text,
            userScore: userScore,
            mlScore: mlScore
        )
    }

    @Test func exportEmptyReturnsHeaderOnly() {
        let csv = CSVExporter.export(entries: [TestEntry]())
        #expect(csv == "timestamp,journalText,userScore,mlScore\n")
    }

    @Test func exportSingleEntry() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!

        let entry = makeEntry(
            timestamp: date,
            text: "Feeling good today",
            userScore: 1,
            mlScore: 2
        )

        let csv = CSVExporter.export(entries: [entry])
        let lines = csv.components(separatedBy: "\n")

        #expect(lines.count == 3) // header + 1 entry + trailing newline
        #expect(lines[0] == "timestamp,journalText,userScore,mlScore")
        #expect(lines[1] == "2026-01-15T10:30:00Z,\"Feeling good today\",1,2")
    }

    @Test func exportEscapesQuotesInText() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!

        let entry = makeEntry(
            timestamp: date,
            text: "Said \"hello\" to doctor",
            userScore: 0,
            mlScore: 0
        )

        let csv = CSVExporter.export(entries: [entry])
        let lines = csv.components(separatedBy: "\n")

        // Quotes in CSV should be escaped as double quotes
        #expect(lines[1] == "2026-01-15T10:30:00Z,\"Said \"\"hello\"\" to doctor\",0,0")
    }

    @Test func exportHandlesCommasInText() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!

        let entry = makeEntry(
            timestamp: date,
            text: "Pain in head, back, and knees",
            userScore: 2,
            mlScore: 3
        )

        let csv = CSVExporter.export(entries: [entry])
        let lines = csv.components(separatedBy: "\n")

        // Text with commas should be quoted
        #expect(lines[1] == "2026-01-15T10:30:00Z,\"Pain in head, back, and knees\",2,3")
    }

    @Test func exportHandlesNewlinesInText() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!

        let entry = makeEntry(
            timestamp: date,
            text: "Line one\nLine two",
            userScore: 1,
            mlScore: 1
        )

        let csv = CSVExporter.export(entries: [entry])

        // Newlines in text should be preserved inside quotes
        #expect(csv.contains("\"Line one\nLine two\""))
    }

    @Test func exportHandlesNilText() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!

        let entry = makeEntry(
            timestamp: date,
            text: nil,
            userScore: 1,
            mlScore: -1
        )

        let csv = CSVExporter.export(entries: [entry])
        let lines = csv.components(separatedBy: "\n")

        #expect(lines[1] == "2026-01-15T10:30:00Z,\"\",1,-1")
    }

    @Test func exportMultipleEntriesSortedByTimestamp() {
        let formatter = ISO8601DateFormatter()

        let older = makeEntry(
            timestamp: formatter.date(from: "2026-01-10T08:00:00Z")!,
            text: "Older entry",
            userScore: 0,
            mlScore: 0
        )

        let newer = makeEntry(
            timestamp: formatter.date(from: "2026-01-15T12:00:00Z")!,
            text: "Newer entry",
            userScore: 1,
            mlScore: 1
        )

        // Pass in wrong order to verify sorting
        let csv = CSVExporter.export(entries: [newer, older])
        let lines = csv.components(separatedBy: "\n")

        // Should be sorted oldest first
        #expect(lines[1].contains("Older entry"))
        #expect(lines[2].contains("Newer entry"))
    }

    // MARK: - Edge Cases

    @Test func exportHandlesUnicodeText() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!

        let entry = makeEntry(
            timestamp: date,
            text: "Schmerzen in Rücken 🤕 und Knien",
            userScore: 2,
            mlScore: 2
        )

        let csv = CSVExporter.export(entries: [entry])

        #expect(csv.contains("Rücken"))
        #expect(csv.contains("🤕"))
    }

    @Test func exportHandlesVeryLongText() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!
        let longText = String(repeating: "Lorem ipsum dolor sit amet. ", count: 100)

        let entry = makeEntry(
            timestamp: date,
            text: longText,
            userScore: 1,
            mlScore: 1
        )

        let csv = CSVExporter.export(entries: [entry])

        #expect(csv.contains(longText))
    }

    @Test func exportHandlesSpecialCharacters() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!

        let entry = makeEntry(
            timestamp: date,
            text: "Tab:\tBackslash:\\ Carriage return:\r",
            userScore: 1,
            mlScore: 1
        )

        let csv = CSVExporter.export(entries: [entry])

        #expect(csv.contains("\t"))
        #expect(csv.contains("\\"))
    }

    @Test func exportHandlesAllScoreCombinations() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!

        // Test all valid score combinations
        let entries = [
            makeEntry(timestamp: date, text: "a", userScore: 0, mlScore: 0),
            makeEntry(timestamp: date, text: "b", userScore: 3, mlScore: 3),
            makeEntry(timestamp: date, text: "c", userScore: 1, mlScore: -1), // -1 = not scored
        ]

        let csv = CSVExporter.export(entries: entries)

        #expect(csv.contains(",0,0"))
        #expect(csv.contains(",3,3"))
        #expect(csv.contains(",1,-1"))
    }

    @Test func exportManyEntries() {
        let formatter = ISO8601DateFormatter()
        let baseDate = formatter.date(from: "2026-01-01T00:00:00Z")!

        let entries = (0..<100).map { i in
            makeEntry(
                timestamp: Calendar.current.date(byAdding: .day, value: i, to: baseDate)!,
                text: "Entry \(i)",
                userScore: Int16(i % 4),
                mlScore: Int16(i % 4)
            )
        }

        let csv = CSVExporter.export(entries: entries)
        let lines = csv.components(separatedBy: "\n")

        // header + 100 entries + trailing newline
        #expect(lines.count == 102)
    }

    @Test func exportHeaderHasCorrectColumns() {
        let csv = CSVExporter.export(entries: [TestEntry]())
        let header = csv.components(separatedBy: "\n").first!

        #expect(header == "timestamp,journalText,userScore,mlScore")

        let columns = header.components(separatedBy: ",")
        #expect(columns.count == 4)
        #expect(columns[0] == "timestamp")
        #expect(columns[1] == "journalText")
        #expect(columns[2] == "userScore")
        #expect(columns[3] == "mlScore")
    }

    @Test func exportEndsWithNewline() {
        let date = ISO8601DateFormatter().date(from: "2026-01-15T10:30:00Z")!
        let entry = makeEntry(timestamp: date, text: "Test", userScore: 1, mlScore: 1)

        let csv = CSVExporter.export(entries: [entry])

        #expect(csv.hasSuffix("\n"))
    }
}

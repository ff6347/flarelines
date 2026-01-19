// ABOUTME: Tests for CSV export functionality.
// ABOUTME: Validates CSV format with timestamp, journalText, userScore, mlScore.

import Foundation
import Testing
@testable import wolfsbit

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
}

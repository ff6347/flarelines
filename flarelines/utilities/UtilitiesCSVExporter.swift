// ABOUTME: Exports journal entries to CSV format for user data backup.
// ABOUTME: Produces RFC 4180 compliant CSV with proper escaping.

import Foundation
import CoreData

/// Protocol for types that can be exported to CSV.
protocol CSVExportable {
    var timestamp: Date { get }
    var journalText: String? { get }
    var userScore: Int16 { get }
    var mlScore: Int16 { get }
}

extension JournalEntry: CSVExportable {}

enum CSVExporter {
    private static let header = "timestamp,journalText,userScore,mlScore"

    /// Exports entries to CSV string.
    /// - Parameter entries: Array of CSVExportable items to export
    /// - Returns: CSV string with header row and data rows
    static func export<T: CSVExportable>(entries: [T]) -> String {
        let sortedEntries = entries.sorted { $0.timestamp < $1.timestamp }

        var lines = [header]

        for entry in sortedEntries {
            let line = formatRow(entry)
            lines.append(line)
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func formatRow<T: CSVExportable>(_ entry: T) -> String {
        let timestamp = formatTimestamp(entry.timestamp)
        let text = escapeCSVField(entry.journalText ?? "")
        let userScore = String(entry.userScore)
        let mlScore = String(entry.mlScore)

        return "\(timestamp),\(text),\(userScore),\(mlScore)"
    }

    private static func formatTimestamp(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    private static func escapeCSVField(_ value: String) -> String {
        // RFC 4180: Fields containing commas, newlines, or quotes must be quoted
        // Quotes within the field are escaped by doubling them
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

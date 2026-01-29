// ABOUTME: Tests for flare score validation and data model constraints.
// ABOUTME: Validates score ranges and entry data integrity.

import Foundation
import Testing
@testable import Flarelines

// MARK: - Flare Score Constants

/// Flare score range validation
enum FlareScore {
    static let remission = 0
    static let mild = 1
    static let moderate = 2
    static let severe = 3

    static let validRange = 0...3
    static let invalidMLScore = -1

    static func isValid(_ score: Int) -> Bool {
        validRange.contains(score)
    }

    static func isValidMLScore(_ score: Int) -> Bool {
        score == invalidMLScore || validRange.contains(score)
    }
}

struct FlareScoreTests {

    // MARK: - Score Validation Tests

    @Test func validScoresInRange() {
        #expect(FlareScore.isValid(0) == true)
        #expect(FlareScore.isValid(1) == true)
        #expect(FlareScore.isValid(2) == true)
        #expect(FlareScore.isValid(3) == true)
    }

    @Test func invalidScoresOutOfRange() {
        #expect(FlareScore.isValid(-1) == false)
        #expect(FlareScore.isValid(4) == false)
        #expect(FlareScore.isValid(100) == false)
    }

    @Test func mlScoreAllowsMinusOne() {
        // ML score can be -1 when not scored yet
        #expect(FlareScore.isValidMLScore(-1) == true)
        #expect(FlareScore.isValidMLScore(0) == true)
        #expect(FlareScore.isValidMLScore(3) == true)
    }

    @Test func mlScoreRejectsOtherNegatives() {
        #expect(FlareScore.isValidMLScore(-2) == false)
        #expect(FlareScore.isValidMLScore(-100) == false)
    }

    // MARK: - Score Constant Tests

    @Test func scoreConstantsHaveCorrectValues() {
        #expect(FlareScore.remission == 0)
        #expect(FlareScore.mild == 1)
        #expect(FlareScore.moderate == 2)
        #expect(FlareScore.severe == 3)
    }

    @Test func validRangeCoversAllScores() {
        #expect(FlareScore.validRange.lowerBound == 0)
        #expect(FlareScore.validRange.upperBound == 3)
    }
}

// MARK: - Date Utility Tests

struct DateUtilityTests {

    @Test func iso8601FormatterProducesExpectedFormat() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        // Create a known date
        var components = DateComponents()
        components.year = 2026
        components.month = 1
        components.day = 15
        components.hour = 10
        components.minute = 30
        components.second = 0
        components.timeZone = TimeZone(identifier: "UTC")

        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: components)!

        let formatted = formatter.string(from: date)
        #expect(formatted == "2026-01-15T10:30:00Z")
    }

    @Test func iso8601FormatterParsesValidString() {
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: "2026-01-15T10:30:00Z")

        #expect(date != nil)
    }

    @Test func iso8601FormatterRejectsInvalidString() {
        let formatter = ISO8601DateFormatter()
        let date = formatter.date(from: "not-a-date")

        #expect(date == nil)
    }
}

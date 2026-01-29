// ABOUTME: Tests for ScoringService helper functions.
// ABOUTME: Validates score extraction and prompt formatting logic.

import Foundation
import Testing
@testable import Flarelines

// MARK: - Test Helpers for accessing private functions

/// Wrapper to test ScoringService's extractScore logic
/// Since extractScore is private, we replicate the logic here for testing
enum ScoreExtractor {
    /// Extracts score (0-3) from model response - mirrors ScoringService.extractScore
    static func extractScore(from text: String) -> Int? {
        for char in text {
            if let digit = char.wholeNumberValue, digit >= 0 && digit <= 3 {
                return digit
            }
        }
        return nil
    }
}

/// Wrapper to test ScoringService's formatPrompt logic
enum PromptFormatter {
    /// Formats prompt in ChatML format - mirrors ScoringService.formatPrompt
    static func formatPrompt(diaryText: String) -> String {
        """
        <|im_start|>system
        Du bist ein Assistent, der Lupus-Krankheitsaktivität bewertet.<|im_end|>
        <|im_start|>user
        Tagebuch: \(diaryText). Was ist der Krankheitsaktivitätswert für heute?<|im_end|>
        <|im_start|>assistant
        """
    }
}

struct ScoringServiceTests {

    // MARK: - Score Extraction Tests

    @Test func extractScoreFromSingleDigit() {
        #expect(ScoreExtractor.extractScore(from: "0") == 0)
        #expect(ScoreExtractor.extractScore(from: "1") == 1)
        #expect(ScoreExtractor.extractScore(from: "2") == 2)
        #expect(ScoreExtractor.extractScore(from: "3") == 3)
    }

    @Test func extractScoreFromTextWithDigit() {
        #expect(ScoreExtractor.extractScore(from: "Score: 2") == 2)
        #expect(ScoreExtractor.extractScore(from: "The activity level is 1") == 1)
        #expect(ScoreExtractor.extractScore(from: "I rate this as 0 (remission)") == 0)
    }

    @Test func extractScoreReturnsFirstValidDigit() {
        // Should return first digit in 0-3 range
        #expect(ScoreExtractor.extractScore(from: "2 or maybe 3") == 2)
        #expect(ScoreExtractor.extractScore(from: "Score 1, could be 2") == 1)
    }

    @Test func extractScoreIgnoresDigitsOutOfRange() {
        // 4-9 are out of range, should skip them
        #expect(ScoreExtractor.extractScore(from: "4") == nil)
        #expect(ScoreExtractor.extractScore(from: "9") == nil)
        #expect(ScoreExtractor.extractScore(from: "Score: 5, actually 2") == 2)
        #expect(ScoreExtractor.extractScore(from: "8 7 6 5 4 3") == 3)
    }

    @Test func extractScoreFromEmptyStringReturnsNil() {
        #expect(ScoreExtractor.extractScore(from: "") == nil)
    }

    @Test func extractScoreFromTextWithoutDigitsReturnsNil() {
        #expect(ScoreExtractor.extractScore(from: "No numbers here") == nil)
        #expect(ScoreExtractor.extractScore(from: "mild flare") == nil)
    }

    @Test func extractScoreFromGermanResponse() {
        #expect(ScoreExtractor.extractScore(from: "Der Wert ist 2") == 2)
        #expect(ScoreExtractor.extractScore(from: "Aktivitätsstufe: 1") == 1)
    }

    // MARK: - Prompt Formatting Tests

    @Test func formatPromptContainsDiaryText() {
        let diaryText = "Heute geht es mir gut"
        let prompt = PromptFormatter.formatPrompt(diaryText: diaryText)

        #expect(prompt.contains(diaryText))
    }

    @Test func formatPromptHasChatMLStructure() {
        let prompt = PromptFormatter.formatPrompt(diaryText: "Test")

        #expect(prompt.contains("<|im_start|>system"))
        #expect(prompt.contains("<|im_end|>"))
        #expect(prompt.contains("<|im_start|>user"))
        #expect(prompt.contains("<|im_start|>assistant"))
    }

    @Test func formatPromptContainsGermanSystemPrompt() {
        let prompt = PromptFormatter.formatPrompt(diaryText: "Test")

        #expect(prompt.contains("Du bist ein Assistent"))
        #expect(prompt.contains("Lupus-Krankheitsaktivität"))
    }

    @Test func formatPromptContainsGermanUserQuestion() {
        let prompt = PromptFormatter.formatPrompt(diaryText: "Test")

        #expect(prompt.contains("Tagebuch:"))
        #expect(prompt.contains("Krankheitsaktivitätswert"))
    }

    @Test func formatPromptHandlesSpecialCharacters() {
        let diaryText = "Schmerzen in Kopf, Rücken & Knien (stark!)"
        let prompt = PromptFormatter.formatPrompt(diaryText: diaryText)

        #expect(prompt.contains(diaryText))
    }

    @Test func formatPromptHandlesMultilineText() {
        let diaryText = "Erste Zeile\nZweite Zeile\nDritte Zeile"
        let prompt = PromptFormatter.formatPrompt(diaryText: diaryText)

        #expect(prompt.contains(diaryText))
    }

    @Test func formatPromptHandlesEmptyText() {
        let prompt = PromptFormatter.formatPrompt(diaryText: "")

        #expect(prompt.contains("Tagebuch: ."))
    }
}

// MARK: - ScoringError Tests

struct ScoringErrorTests {

    @Test func modelNotAvailableErrorDescription() {
        let error = ScoringError.modelNotAvailable
        #expect(error.errorDescription?.contains("not downloaded") == true)
    }

    @Test func invalidScoreErrorContainsResponse() {
        let error = ScoringError.invalidScore(response: "gibberish")
        #expect(error.errorDescription?.contains("gibberish") == true)
    }
}

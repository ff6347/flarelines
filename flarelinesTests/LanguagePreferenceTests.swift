// ABOUTME: Tests for AppLanguage enum and locale detection logic.
// ABOUTME: Validates language detection, display names, and locale creation.

import Foundation
import Testing
@testable import Flarelines

struct LanguagePreferenceTests {

    // MARK: - AppLanguage Enum Tests

    @Test func englishRawValue() {
        #expect(AppLanguage.english.rawValue == "en")
    }

    @Test func germanRawValue() {
        #expect(AppLanguage.german.rawValue == "de")
    }

    @Test func englishDisplayName() {
        #expect(AppLanguage.english.displayName == "English")
    }

    @Test func germanDisplayName() {
        #expect(AppLanguage.german.displayName == "Deutsch")
    }

    @Test func englishLocaleIdentifier() {
        #expect(AppLanguage.english.locale.identifier == "en")
    }

    @Test func germanLocaleIdentifier() {
        #expect(AppLanguage.german.locale.identifier == "de")
    }

    @Test func allCasesContainsBothLanguages() {
        let allCases = AppLanguage.allCases
        #expect(allCases.count == 2)
        #expect(allCases.contains(.english))
        #expect(allCases.contains(.german))
    }

    @Test func identifiableIdMatchesRawValue() {
        #expect(AppLanguage.english.id == AppLanguage.english.rawValue)
        #expect(AppLanguage.german.id == AppLanguage.german.rawValue)
    }

    @Test func initFromValidRawValue() {
        #expect(AppLanguage(rawValue: "en") == .english)
        #expect(AppLanguage(rawValue: "de") == .german)
    }

    @Test func initFromInvalidRawValueReturnsNil() {
        #expect(AppLanguage(rawValue: "fr") == nil)
        #expect(AppLanguage(rawValue: "es") == nil)
        #expect(AppLanguage(rawValue: "") == nil)
    }
}

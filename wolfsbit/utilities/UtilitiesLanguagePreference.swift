// ABOUTME: Manages app language preference with iOS locale auto-detection.
// ABOUTME: English is default; German detected from iOS settings.

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case german = "de"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .german: return "Deutsch"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// Detects language from iOS settings. Returns German only if device is set to German.
    static func fromSystemLocale() -> AppLanguage {
        let preferredLanguages = Locale.preferredLanguages

        // Check if any preferred language starts with "de"
        for language in preferredLanguages {
            if language.hasPrefix("de") {
                return .german
            }
        }

        return .english
    }
}

@Observable
final class LanguagePreference {
    static let shared = LanguagePreference()

    private let languageKey = "preferredLanguage"
    private let hasDetectedKey = "hasDetectedLanguage"

    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        }
    }

    var locale: Locale {
        language.locale
    }

    private init() {
        // Check if we've already detected/set a language
        let hasDetected = UserDefaults.standard.bool(forKey: hasDetectedKey)

        if hasDetected, let stored = UserDefaults.standard.string(forKey: languageKey),
           let storedLanguage = AppLanguage(rawValue: stored) {
            self.language = storedLanguage
        } else {
            // First launch: detect from iOS settings
            let detected = AppLanguage.fromSystemLocale()
            self.language = detected
            UserDefaults.standard.set(detected.rawValue, forKey: languageKey)
            UserDefaults.standard.set(true, forKey: hasDetectedKey)
        }
    }
}

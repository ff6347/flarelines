# Plan: iOS Localization (English + German)

**Status: IMPLEMENTED**

## Summary

Add full localization support for English and German, with in-app language selection and auto-detected defaults.

## Implementation (Completed)

### 1. Language Preference Model
File: `wolfsbit/utilities/UtilitiesLanguagePreference.swift`

- `AppLanguage` enum with `.english` and `.german` cases
- `LanguagePreference` singleton using `@Observable`
- Auto-detects from iOS locale on first launch (German if iOS is German, else English)
- Persists selection in UserDefaults

### 2. App Root Locale Override
File: `wolfsbit/wolfsbitApp.swift`

- `LocalizedRootView` wrapper applies `.environment(\.locale, ...)` reactively
- Locale updates immediately when user changes language in onboarding

### 3. Language Picker in Onboarding
File: `wolfsbit/views/ViewsOnboardingView.swift`

- Two-button picker (English / Deutsch) on welcome page
- Uses DesignTokens for styling
- Selection persists and updates app immediately

### 4. German Translations
File: `wolfsbit/Localizable.xcstrings`

- ~90 strings translated to German
- Uses String Catalog format (Xcode 15+), not .strings files
- No .lproj folders needed with String Catalogs

### 5. Speech Recognition Locale
File: `wolfsbit/utilities/UtilitiesSpeechRecognizer.swift`

- Changed from hardcoded `en-US` to use `LanguagePreference.shared.locale`
- Speech recognizer created on-demand with current locale

## Files Changed

**Added:**
- `wolfsbit/utilities/UtilitiesLanguagePreference.swift`

**Modified:**
- `wolfsbit/wolfsbitApp.swift` - locale environment
- `wolfsbit/views/ViewsOnboardingView.swift` - language picker
- `wolfsbit/Localizable.xcstrings` - German translations
- `wolfsbit/utilities/UtilitiesSpeechRecognizer.swift` - dynamic locale

## Notes

- Did NOT use `.lproj` folders - String Catalogs handle this
- Did NOT need `String.localized` extension - SwiftUI `Text()` auto-localizes
- InfoPlist.strings not needed for iOS 15+ with String Catalogs

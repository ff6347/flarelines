# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Bug Fixes
- fix(persistence): remove destructive data deletion
- fix: remove explicit CODE_SIGN_IDENTITY for Release builds

## [1.1.0] - 2026-01-29

### Features
- feat: add drag-to-select range on chart
- feat: add 'All' option to time range picker

### Bug Fixes
- fix: implement daily reminder notifications (#19)
- fix(i18n): change rating screen wording from "activity" to "flare" (#18)
- fix: restore drag-to-select range functionality
- fix: restore tap-to-select entry while keeping drag-to-range
- fix: zoom chart to selected date range
- fix: make chart selection persistent and increase tap target
- fix: make Journal Entries header sticky
- fix: make chart sticky while journal entries list scrolls
- fix: expand chart X-axis to show full selected time range
- fix: chart timeframe switching and add tap-to-show-info
- fix: Restore Core Data model name to match actual file
- fix: Remove stored @Observable references causing crash

## [1.0.0] - 2026-01-25

### Features
- feat: rename app to Flareline
- feat: add app icon
- feat: add light theme support with adaptive colors (#10)
- feat(ml-scoring): show phase-specific status messages
- feat(data): add CSV export for journal entries (#9)
- feat: support iOS 17+
- feat(score-flow): pre-fill slider with ML inference on page transition
- feat(onboarding): add About This Project page with data contribution consent
- feat(i18n): add German translations for consent and onboarding
- feat(settings): add data contribution consent toggle
- feat(ios): add analytics signals for key user actions
- feat(ios): add TelemetryDeck analytics integration
- feat(ios): add English/German localization with in-app language picker
- feat(ios): integrate model download into onboarding with pause/resume
- feat(ios): add Settings UI for ML model download
- feat(ios): add on-device ML scoring with llama.cpp
- feat(ios): redesign UI with full-screen journal editor
- feat(onboarding): add 5-page onboarding system
- feat(data): add entry editing functionality
- feat(voice): improve UX with live transcription and locked navigation
- feat(model): add ML scoring fields to JournalEntry
- feat(model): add DoctorVisit entity for tracking visits

### Bug Fixes
- fix(download): move temp file synchronously before delegate returns
- fix(data): correct share sheet presentation for UIKit interop
- fix(onboarding): reset page to 0 on completion
- fix(onboarding): use SceneStorage to prevent page reset on language change
- fix(ios): update privacy and terms URLs in Settings
- fix(ios): correct help text to reference bottom toolbar
- fix(ios): defer permission prompts until user action
- fix(ios): prevent layout shift when download progress appears
- fix(ios): prevent duplicate model downloads
- fix(ios): use continuous corners to match native iOS styling
- fix(speech): remove existing audio tap before installing new one
- fix(speech): refactor to use centralized reset() method

[Unreleased]: https://github.com/ff6347/flarelines/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/ff6347/flarelines/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/ff6347/flarelines/releases/tag/v1.0.0

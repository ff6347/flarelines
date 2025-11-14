# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Wolfsbit is a chronic illness journaling iOS app built with SwiftUI, Core Data, and Swift Charts. Users answer daily health questions via text or voice input, and track their health progress over time through visualizations.

## Development Commands

### Building and Running
- **Build**: `Cmd+B` in Xcode
- **Run**: `Cmd+R` in Xcode
- **Clean Build Folder**: `Cmd+Shift+K`

### Testing Voice Input
Voice input requires:
1. Info.plist entries for `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription`
2. Running on a device or simulator with microphone access
3. Granting permissions when prompted

### No Traditional Package Manager
This is a native iOS project using Xcode's standard frameworks. No npm, yarn, or CocoaPods.

## Architecture

### MVVM Pattern
- **Models**: Data structures (`JournalEntry`, `HealthQuestion`)
- **ViewModels**: Business logic (`JournalViewModel` manages question flow and Core Data persistence)
- **Views**: SwiftUI components (`LogView`, `DataView`, `HelpView`, `SettingsView`)
- **Utilities**: Reusable components (`SpeechRecognizer` for voice input, `DesignTokens` for styling)

### Core Data Setup
The app uses Core Data with a `JournalEntry` entity:
- **Attributes**: `id` (UUID), `timestamp` (Date), `feeling` (String?), `painLevel` (Int16), `symptoms` (String?), `healthScore` (Double)
- **Persistence**: Managed through `PersistenceController.shared`
- **Important**: Core Data model (`wolfsbit.xcdatamodeld`) must have `JournalEntry` entity with Codegen set to "Manual/None"

### Question Flow System
The app uses a structured question system:
1. Three hardcoded questions in `HealthQuestion.defaultQuestions`
2. `JournalViewModel` manages current question index and user answers
3. Answers stored in dictionary keyed by question ID
4. Pain level (question 2) is extracted and used to calculate health score: `healthScore = 10.0 - painLevel`

### Voice Recognition Integration
- `SpeechRecognizer` class handles iOS Speech framework integration
- Authorization requested on init
- Real-time transcription with partial results
- Audio engine manages microphone input
- Transcript published to SwiftUI views via `@Published` properties

### Data Visualization
- Uses Swift Charts (`Chart`, `LineMark`, `PointMark`) to plot health scores over time
- Time range filtering: 7D, 30D, 90D, 180D, 1Y
- Chart data filtered from Core Data fetch results based on timestamp

## File Naming Convention
All Swift files use PascalCase with type prefix to avoid folder structure:
- Models: `ModelsJournalEntry.swift`, `ModelsHealthQuestion.swift`
- ViewModels: `ViewModelsJournalViewModel.swift`
- Views: `ViewsLogView.swift`, `ViewsDataView.swift`, etc.
- Utilities: `UtilitiesSpeechRecognizer.swift`, `UtilitiesDesignTokens.swift`

This is unusual but intentional for this project's flat file structure.

## Key Technical Decisions

### Health Score Calculation
Health score is inversely proportional to pain level: a pain level of 7/10 results in a health score of 3.0. This provides intuitive visualization where higher scores = better health.

### Speech Recognition Language
Hardcoded to `en-US` locale in `SpeechRecognizer`. To support other languages, modify the `SFSpeechRecognizer` initialization.

### Data Persistence Strategy
- All data stored locally in Core Data (no cloud sync)
- Auto-save on question navigation using `automaticallyMergesChangesFromParent`
- Preview environment uses in-memory store with sample data

### SwiftUI Previews
Core Data previews use `PersistenceController.preview` which creates an in-memory store with 10 sample entries. This allows views to be previewed without affecting production data.

## Common Development Tasks

### Adding New Questions
Modify `HealthQuestion.defaultQuestions` in `ModelsHealthQuestion.swift`. Update `JournalViewModel.saveEntry()` to handle the new question's answer appropriately.

### Changing Colors/Styling
Edit `UtilitiesDesignTokens.swift` for centralized design tokens. The app uses a monochrome design with black accents.

### Modifying Chart Display
Edit `ViewsDataView.swift`. Chart configuration includes:
- Y-axis scale: `chartYScale(domain: 0...10)`
- Interpolation: `.interpolationMethod(.catmullRom)` for smooth curves
- Time filtering via `filteredEntries` computed property

### Export Functionality (Not Yet Implemented)
Settings view has a placeholder "Export Data" button. To implement, add logic to export Core Data entries to CSV/JSON format.

## iOS-Specific Considerations

### Minimum Deployment Target
- iOS 17.0+ required for Swift Charts and modern SwiftUI features
- Speech framework available since iOS 10.0
- Core Data available on all iOS versions

### Permissions Workflow
1. User taps microphone button in LOG view
2. `SpeechRecognizer.requestAuthorization()` prompts for speech recognition
3. Audio session activation prompts for microphone access
4. Denied permissions prevent voice input but don't crash the app

### Main Actor Usage
`JournalViewModel` and `SpeechRecognizer` use `@MainActor` to ensure UI updates happen on the main thread. This is critical for `@Published` properties that drive SwiftUI views.

## Known Limitations

- No multi-language support (hardcoded to English)
- Pain level extraction from text is basic (first number found)
- No data export yet (planned feature)
- No iCloud sync (all data local only)
- No medication tracking (future enhancement)

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flareline is a chronic illness journaling iOS app built with SwiftUI, Core Data, and Swift Charts. Users answer daily health questions via text or voice input, and track their health progress over time through visualizations.

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

## File Organization
The project uses an organized folder structure with lowercase folder names:
- **Models**: `flarelines/models/` - Contains `ModelsJournalEntry.swift`, `ModelsHealthQuestion.swift`
- **Views**: `flarelines/views/` - Contains `ViewsLogView.swift`, `ViewsDataView.swift`, `ViewsHelpView.swift`, `ViewsSettingsView.swift`
- **ViewModels**: `flarelines/views/` - Contains `ViewModelsJournalViewModel.swift` (located with views for convenience)
- **Utilities**: `flarelines/utilities/` - Contains `UtilitiesSpeechRecognizer.swift`, `UtilitiesDesignTokens.swift`, `UtilitiesSampleDataGenerator.swift`

All Swift files use PascalCase names with type prefixes (Models*, Views*, Utilities*) for clarity and easy identification.

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
Modify `HealthQuestion.defaultQuestions` in `flarelines/models/ModelsHealthQuestion.swift`. Update `JournalViewModel.saveEntry()` in `flarelines/views/ViewModelsJournalViewModel.swift` to handle the new question's answer appropriately.

### Changing Colors/Styling
Edit `flarelines/utilities/UtilitiesDesignTokens.swift` for centralized design tokens. The app uses a monochrome design with black accents.

### Modifying Chart Display
Edit `flarelines/views/ViewsDataView.swift`. Chart configuration includes:
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

<!-- bv-agent-instructions-v1 -->

---

## Beads Workflow Integration

This project uses [beads_viewer](https://github.com/Dicklesworthstone/beads_viewer) for issue tracking. Issues are stored in `.beads/` and tracked in git.

### Essential Commands

```bash
# View issues (launches TUI - avoid in automated sessions)
bv

# CLI commands for agents (use these instead)
bd ready              # Show issues ready to work (no blockers)
bd list --status=open # All open issues
bd show <id>          # Full issue details with dependencies
bd create --title="..." --type=task --priority=2
bd update <id> --status=in_progress
bd close <id> --reason="Completed"
bd close <id1> <id2>  # Close multiple issues at once
bd sync               # Commit and push changes
```

### Workflow Pattern

1. **Start**: Run `bd ready` to find actionable work
2. **Claim**: Use `bd update <id> --status=in_progress`
3. **Work**: Implement the task
4. **Complete**: Use `bd close <id>`
5. **Sync**: Always run `bd sync` at session end

### Key Concepts

- **Dependencies**: Issues can block other issues. `bd ready` shows only unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog (use numbers, not words)
- **Types**: task, bug, feature, epic, question, docs
- **Blocking**: `bd dep add <issue> <depends-on>` to add dependencies

### Session Protocol

**Before ending any session, run this checklist:**

```bash
git status              # Check what changed
git add <files>         # Stage code changes
bd sync                 # Commit beads changes
git commit -m "..."     # Commit code
bd sync                 # Commit any new beads changes
git push                # Push to remote
```

### Best Practices

- Check `bd ready` at session start to find available work
- Update status as you work (in_progress → closed)
- Create new issues with `bd create` when you discover tasks
- Use descriptive titles and set appropriate priority/type
- Always `bd sync` before ending session

<!-- end-bv-agent-instructions -->

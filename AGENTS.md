# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) and other agents when working with code in this repository.

## Project Overview

Flarelines is a chronic illness journaling iOS app built with SwiftUI, Core Data, and Swift Charts. Users write daily diary entries via text or voice input, rate their flare severity (0-3), and track their health progress over time through visualizations. On-device ML suggests flare scores based on diary text.

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

### MVVM-ish Pattern
- **Models**: `flarelines/models/` - Core Data entities
- **Views**: `flarelines/views/` - SwiftUI components with embedded view logic
- **Utilities**: `flarelines/utilities/` - Reusable services and helpers

### Core Data Setup
The app uses Core Data with a `JournalEntry` entity in `flarelines.xcdatamodeld`:
- **Attributes**: `id` (UUID), `timestamp` (Date), `journalText` (String?), `userScore` (Int16, 0-3), `mlScore` (Int16, 0-3 or -1 if not scored)
- **Persistence**: Managed through `PersistenceController.shared`
- **Important**: Core Data model must have `JournalEntry` entity with Codegen set to "Manual/None"

### Two-Step Entry Flow
The journal editor (`ViewsLogView.swift`) has two pages:
1. **Text Entry**: Free-form diary text with optional voice input
2. **Flare Rating**: Slider (0-3) with labels: Remission, Mild, Moderate, Severe

When the user navigates to the rating page, the ML model analyzes the text and suggests a score. The user can accept or adjust before saving.

### ML Scoring System
On-device ML scoring using GGUF models:
- `UtilitiesScoringService.swift` - Orchestrates scoring requests
- `LlamaContext.swift` - llama.cpp integration for model inference
- `ModelDownloader.swift` - Downloads models from remote manifest
- `UtilitiesModelManifest.swift` / `UtilitiesModelStorage.swift` - Model management

The ML model runs entirely on-device. No data leaves the phone.

### Voice Recognition
- `UtilitiesSpeechRecognizer.swift` handles iOS Speech framework
- Real-time transcription with partial results
- Supports multiple languages via `UtilitiesLanguagePreference.swift`

### Data Visualization
- `ViewsDataView.swift` uses Swift Charts (`Chart`, `LineMark`, `PointMark`)
- Y-axis scale: `chartYScale(domain: 0...3)`
- Time range filtering: 7D, 30D, 90D, 180D, 1Y
- Interpolation: `.catmullRom` for smooth curves

## File Organization

```
flarelines/
├── models/
│   ├── ModelsJournalEntry.swift      # Core Data entity
│   └── ModelsDoctorVisit.swift       # Doctor visit tracking
├── views/
│   ├── ViewsLogView.swift            # Main journal editor (two-step flow)
│   ├── ViewsDataView.swift           # Charts and entry history
│   ├── ViewsEditEntryView.swift      # Edit existing entries
│   ├── ViewsHelpView.swift           # Help/FAQ screen
│   ├── ViewsSettingsView.swift       # Settings and export
│   ├── ViewsOnboardingView.swift     # First-launch onboarding
│   └── ViewsDataContributionConsentSheet.swift
├── utilities/
│   ├── UtilitiesSpeechRecognizer.swift    # Voice input
│   ├── UtilitiesScoringService.swift      # ML scoring orchestration
│   ├── UtilitiesDesignTokens.swift        # Centralized styling
│   ├── UtilitiesCSVExporter.swift         # Data export
│   ├── UtilitiesSampleDataGenerator.swift # Preview/test data
│   ├── UtilitiesLanguagePreference.swift  # Language settings
│   ├── UtilitiesAnalytics.swift           # Usage analytics
│   ├── LlamaContext.swift                 # llama.cpp wrapper
│   ├── ModelDownloader.swift              # ML model download
│   ├── UtilitiesModelManifest.swift       # Model metadata
│   └── UtilitiesModelStorage.swift        # Model file management
├── ContentView.swift                 # Root view
├── flarelinesApp.swift               # App entry point
├── AppDelegate.swift                 # Notifications setup
└── Persistence.swift                 # Core Data stack
```

All Swift files use PascalCase names with type prefixes for clarity.

## Key Technical Decisions

### Flare Score Scale
- 0 = Remission
- 1 = Mild
- 2 = Moderate
- 3 = Severe

Higher scores indicate worse symptoms. The chart plots `userScore` (what the user saved, possibly adjusted from ML suggestion).

### Data Persistence Strategy
- All data stored locally in Core Data (no cloud sync)
- Auto-save with `automaticallyMergesChangesFromParent`
- Preview environment uses in-memory store with sample data

### Localization
The app supports multiple languages via `Localizable.xcstrings`. Currently English and German.

### SwiftUI Previews
Core Data previews use `PersistenceController.preview` which creates an in-memory store with sample entries.

## Common Development Tasks

### Version Control

Make sure we are not working on the `main` branch. All work should allways be on feature branches. eg `feat/my-cool-feautre` or `fix/buggy-thing` and so on.
Attribute your work on git commits as co-author.
Allways use convetional commits, `feat(<scope>): <Description>` or `fix(<scope>): <Description>` or similar (`chore`, `ci`, `style`).
Things like changes to README.md files or docs should not trigger a ci run. use `skip ci` in those commits.


### Changing Colors/Styling
Edit `flarelines/utilities/UtilitiesDesignTokens.swift` for centralized design tokens.

### Modifying Chart Display
Edit `flarelines/views/ViewsDataView.swift`. Chart configuration:
- Y-axis: `chartYScale(domain: 0...3)`
- Interpolation: `.interpolationMethod(.catmullRom)`
- Time filtering via `filteredEntries` computed property

### Adding Translations
Edit `flarelines/Localizable.xcstrings` - Xcode's string catalog format.

### Export Functionality
CSV export is implemented in `UtilitiesCSVExporter.swift`, triggered from Settings.

## iOS-Specific Considerations

### Minimum Deployment Target
- iOS 17.0+ required for Swift Charts and modern SwiftUI features

### Permissions
- Microphone: For voice input
- Speech Recognition: For transcription
- Notifications: For reminders

### Main Actor Usage
Views and services use `@MainActor` to ensure UI updates happen on the main thread.

## Known Limitations

- No iCloud sync (all data local only)
- Reminders not working (P1 bug: wolfsbit-01-29a)
- Log view shows stale data after editing (P2 bug: wolfsbit-01-rl7)

<!-- bv-agent-instructions-v1 -->

---

## Beads Workflow Integration

This project uses beads for issue tracking. Issues are stored in `.beads/issues.jsonl` and tracked in git. This is a solo developer project - only Claude manages beads.

### Essential Commands

```bash
bd ready              # Show issues ready to work (no blockers)
bd list --status=open # All open issues
bd show <id>          # Full issue details with dependencies
bd create --title="..." --type=task --priority=2
bd update <id> --status=in_progress
bd close <id> --reason="Completed"
bd close <id1> <id2>  # Close multiple issues at once
```

### Workflow Pattern

1. **Start**: Run `bd ready` to find actionable work
2. **Claim**: Use `bd update <id> --status=in_progress`
3. **Work**: Implement the task
4. **Complete**: Use `bd close <id>`

### Key Concepts

- **Dependencies**: Issues can block other issues. `bd ready` shows only unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog (use numbers, not words)
- **Types**: task, bug, feature, epic, question, docs

### Session Protocol

Beads changes are committed with code changes. No special sync needed.

```bash
git status                      # Check what changed
git add <files> .beads/         # Stage code AND beads changes together
git commit -m "..."             # Commit everything
git push                        # Push to remote
```

**Important:** Do NOT use `bd sync --from-main` - it creates unnecessary worktrees. Just commit `.beads/issues.jsonl` with your other changes.

<!-- end-bv-agent-instructions -->

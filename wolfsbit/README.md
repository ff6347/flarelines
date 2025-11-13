# Wolfsbit - Chronic Illness Journal App

A journaling app designed to help users track chronic illnesses through daily diary entries and visualize health progress over time.

## Features

### 📝 LOG View
- Question-based journaling system (3 daily questions)
- Voice input support using iOS Speech Recognition
- Editable text input with auto-save
- Progress tracking through questions
- Previous/Next navigation

### 📊 DATA View
- Health progress visualization using Swift Charts
- Time range filtering (7D, 30D, 90D, 180D, 1Y)
- Detailed journal entries grouped by date
- Pain level tracking (0-10 scale)
- Symptoms and feelings logging

### ❓ HELP View
- Getting started guide
- Feature documentation
- Privacy information

### ⚙️ Settings View
- Daily reminder notifications
- Data export functionality
- Privacy and terms links

## Technical Stack

- **SwiftUI** - Modern declarative UI framework
- **Core Data** - Local data persistence
- **Swift Charts** - Health progress visualization
- **Speech Framework** - Voice-to-text transcription
- **MVVM Architecture** - Clean separation of concerns

## Setup Instructions

### 1. Core Data Model Setup

You need to update your Core Data model (`.xcdatamodeld` file) to include the `JournalEntry` entity:

**Entity: JournalEntry**
- `id` (UUID) - Unique identifier
- `timestamp` (Date) - Entry creation time
- `feeling` (String, Optional) - Answer to "How are you feeling?"
- `painLevel` (Integer 16) - Pain rating 0-10
- `symptoms` (String, Optional) - Symptom descriptions
- `healthScore` (Double) - Calculated health score (0-10)

To add this in Xcode:
1. Open `wolfsbit.xcdatamodeld`
2. Click "+" to add a new entity
3. Name it "JournalEntry"
4. Add the attributes listed above with their respective types
5. Set the Codegen to "Manual/None" (we've provided the Swift class)

### 2. Info.plist Configuration

Add the following privacy descriptions for microphone and speech recognition:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Wolfsbit needs microphone access to record your journal entries using voice input.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Wolfsbit uses speech recognition to transcribe your voice into text for journal entries.</string>
```

### 3. File Organization

The project is organized as follows:

```
wolfsbit/
├── Models/
│   ├── JournalEntry.swift
│   └── HealthQuestion.swift
├── ViewModels/
│   └── JournalViewModel.swift
├── Views/
│   ├── LogView.swift
│   ├── DataView.swift
│   ├── HelpView.swift
│   └── SettingsView.swift
├── Utilities/
│   └── SpeechRecognizer.swift
├── ContentView.swift
├── Persistence.swift
└── wolfsbitApp.swift
```

## Usage

### Logging an Entry

1. Open the app to the LOG tab
2. Answer each question by typing or using voice input
3. Tap the microphone button to start voice recording
4. Tap "Next" to proceed through questions
5. Tap "Save" on the final question to store your entry

### Viewing Your Data

1. Switch to the DATA tab
2. View your health progress chart at the top
3. Select different time ranges (7D, 30D, etc.)
4. Scroll down to see detailed journal entries
5. Entries are grouped by date with all questions and answers

### Voice Input Tips

- Grant microphone and speech recognition permissions when prompted
- Speak clearly and at a normal pace
- The app will show live transcription while recording
- Tap the microphone button again to stop recording
- Edit the transcribed text before moving to the next question

## Health Score Calculation

The health score is automatically calculated based on your pain level:
- **Health Score = 10 - Pain Level**
- Lower pain = Higher health score
- This provides an inverse correlation for chart visualization

## Privacy & Security

- All data is stored locally on your device using Core Data
- No data is transmitted to external servers
- Speech recognition uses on-device processing when available
- You control all your health information

## Future Enhancements

- [ ] Export data to CSV/PDF
- [ ] Custom questions configuration
- [ ] Medication tracking
- [ ] Photo attachments
- [ ] Health trend analysis
- [ ] iCloud sync across devices
- [ ] Widget support for quick logging

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## License

Copyright © 2025 Fabian Moron Zirfas. All rights reserved.

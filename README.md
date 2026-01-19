# Wolfsbit

Track your chronic illness journey, your way, your device.

## About

Living with chronic illness means good days and bad days. Remembering symptoms for doctor visits is hard when you're exhausted. Wolfsbit helps you journal your symptoms with voice-first input and on-device AI that keeps your health data private.

Wolfsbit is a research artifact of the master studies of Fabian Moron Zirfas at University of Applied Sciences Potsdam, Germany, exploring on-device usage of small language models (SLM) for symptom diary patient-reported outcome measures (PROM).

## Features

**Voice-first.** Tap the microphone, speak naturally. For days when typing feels like too much.

**AI scoring.** On-device AI analyzes your entries and suggests activity scores (0-3). All processing happens locally—your words never leave your phone.

**Doctor reports.** Generate summaries for healthcare providers. See patterns, identify flare-ups.

**Localization.** German and English localized.

## Privacy

Your health data is stored only on your device. No cloud sync, no accounts. Export when you want, delete when you want. We use [Telemetry Deck](https://telemetrydeck.com/) to collect anonymized usage patterns.

## Technical Stack

- **SwiftUI** - Declarative UI framework
- **Core Data** - Local data persistence
- **Swift Charts** - Progress visualization
- **Speech Framework** - Voice-to-text transcription
- **Core ML** - On-device SLM inference

## Requirements

- iOS 17.6 or later
- Xcode 15.0 or later

## Setup

### Core Data Model

The app uses Core Data with a `JournalEntry` entity. Open `wolfsbit.xcdatamodeld` and ensure the entity is configured with Codegen set to "Manual/None".

### Info.plist

Add the following privacy descriptions:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Wolfsbit needs microphone access to record your journal entries using voice input.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Wolfsbit uses speech recognition to transcribe your voice into text for journal entries.</string>
```

## Contributing

If you want to contribute to the project, you can share your journal entries and scoring with us so we can train the model further to generate better results.

Feel free to open issues or pull requests on [GitHub](https://github.com/ff6347/wolfsbit).

## Contact

Research inquiries: wolfsbit@inpyjamas.dev

## License

Copyright 2025-2026 Fabian Moron Zirfas. All rights reserved.

# Voice Input Crash Bug - AVAudioEngine Tap Issue

## Problem Summary

The app crashes when using voice input on multiple questions in sequence. Voice input works fine on the first question, but crashes when used on the second question (or after stopping/starting multiple times).

## Error Details

**Error 1 (Initial):**
```
Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio'
reason: 'required condition is false: nullptr == Tap()'
```

**Error 2 (After first fix):**
```
Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio'
reason: 'required condition is false: IsFormatSampleRateAndChannelCountValid(format)'
```

**Current Issue (After refactoring):**
Voice input button triggers recording but immediately stops. On second tap, app crashes with the nullptr Tap error again.

## File Location

`/Users/tomato/Documents/apps/wolfsbit/wolfsbit/utilities/UtilitiesSpeechRecognizer.swift`

## Current Implementation

The SpeechRecognizer class uses AVAudioEngine for voice input:
- Uses `AVAudioEngine` with `inputNode.installTap(onBus: 0, ...)`
- Speech recognition via `SFSpeechRecognizer`
- Manages start/stop recording with `isRecording` @Published property

**Current structure:**
```swift
class SpeechRecognizer: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    func startRecording() throws {
        reset() // Clean up previous state
        // Configure audio session
        // Create recognition request
        // Install tap on inputNode
        // Start audio engine
    }

    func stopRecording() {
        recognitionRequest?.endAudio()
        reset()
    }

    private func reset() {
        // Cancel tasks
        // Stop audio engine
        // Remove tap from inputNode
    }
}
```

## Attempted Fixes (All Failed)

1. **Remove tap before installing new one** - Still crashed
2. **Use nil format instead of outputFormat(forBus:)** - Still crashed
3. **Refactor to centralized reset() method** - Still crashes

## Usage Context

The SpeechRecognizer is used in `ViewsLogView.swift`:
```swift
Button(action: {
    if speechRecognizer.isRecording {
        speechRecognizer.stopRecording()
        currentAnswer += speechRecognizer.transcript
    } else {
        try speechRecognizer.startRecording()
    }
})
```

User flow:
1. Tap mic button on Question 1 → Works ✓
2. Recording stops (either auto or manual)
3. Navigate to Question 2
4. Tap mic button → **CRASH** ❌

## Root Cause Hypothesis

The AVAudioEngine tap is not being properly cleaned up between recording sessions. Possible issues:
- Race condition between cleanup and new tap installation
- Audio engine state not fully reset
- Tap removal failing silently
- SwiftUI state updates causing multiple reset() calls

## What We Need

A robust implementation of SpeechRecognizer that:
1. Properly cleans up AVAudioEngine tap between recordings
2. Handles multiple start/stop cycles without crashing
3. Works when navigating between SwiftUI views
4. Doesn't have race conditions between cleanup and initialization

## Environment

- Xcode 26.1 (build 24454)
- iOS 26.1 simulator (iPhone 17 Pro)
- Target: iOS 17.0+
- Language: Swift 6.0

## Question

Can you fix the SpeechRecognizer implementation to prevent the AVAudioEngine tap crash when using voice input multiple times across different questions?

The key issue seems to be that `inputNode.installTap()` throws "nullptr == Tap()" even though we're calling `removeTap(onBus: 0)` before installing a new tap.

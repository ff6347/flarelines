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
NOW FAILS ON FIRST TAP - worse than before. Audio engine fails to initialize at all.

**Error 3 (Latest - Audio Unit failure):**
```
AddInstanceForFactory: No factory registered for id <CFUUID 0x600000238ac0> F8BB1C28-BAE8-11D6-9C31-00039315CD46
AURemoteIO.cpp:1135  failed: -10851 (enable 1, outf< 2 ch, 0 Hz, Float32, deinterleaved> inf< 2 ch, 0 Hz, Float32, deinterleaved>)
HALC_ShellPlugIn.cpp:915    HAL_HardwarePlugIn_ObjectHasProperty: no object
HALSystem.cpp:2229   AudioObjectPropertiesChanged: no such object
SetProperty: RPC timeout. Apparently deadlocked. Aborting now.
```

**Error Code:** `-10851` = `kAudioUnitErr_NoConnection` (Audio Unit cannot connect to hardware)

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
1. Tap mic button on Question 1 → **CRASH** ❌ (after latest refactoring)

Previous behavior (before refactoring):
1. Tap mic button on Question 1 → Works ✓
2. Recording stops (either auto or manual)
3. Navigate to Question 2
4. Tap mic button → **CRASH** ❌

## Root Cause Analysis

**Primary Issue: iOS Simulator Audio Limitations**

The latest error (`-10851 kAudioUnitErr_NoConnection`) reveals the core problem is with the **Audio Unit Remote I/O** component failing to initialize properly on the simulator, especially after stop/restart cycles.

**Root causes:**
1. **Simulator audio hardware emulation is fragile** - Audio Units don't properly reset between sessions
2. **Audio session not fully deactivating** - Session remains in a bad state after stopping
3. **Race condition in audio engine lifecycle** - Starting too soon after stopping
4. **Output format has invalid sample rate (0 Hz)** - Indicates audio engine initialization failure

**Additional issues:**
- AVAudioEngine tap is not being properly cleaned up between recording sessions
- Audio engine state not fully reset before restart
- Tap removal may be failing silently
- SwiftUI state updates may be causing multiple reset() calls

## What We Need

A robust implementation of SpeechRecognizer that:
1. **Handles iOS Simulator audio limitations** - Gracefully handles Audio Unit failures
2. **Properly resets the audio session** - Fully deactivate/reactivate between sessions
3. **Avoids race conditions** - Add appropriate delays or synchronization
4. **Cleans up AVAudioEngine tap completely** - No leftover taps between recordings
5. **Handles multiple start/stop cycles** - Works reliably across questions
6. **Works when navigating between SwiftUI views** - State persists correctly

## Potential Solutions

1. **Full audio session reset between recordings:**
   ```swift
   try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
   // Small delay to let hardware reset
   try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
   ```

2. **Recreate AVAudioEngine instance** - Don't reuse the same instance
   - Create new `AVAudioEngine()` on each startRecording()
   - Prevents accumulated state issues

3. **Add async/await delays** - Give audio hardware time to reset:
   ```swift
   try await Task.sleep(nanoseconds: 100_000_000) // 100ms
   ```

4. **Better error handling** - Catch and recover from Audio Unit failures:
   ```swift
   do {
       try audioEngine.start()
   } catch {
       // Retry with fresh audio session
   }
   ```

5. **Simulator detection** - Different behavior for simulator vs device:
   ```swift
   #if targetEnvironment(simulator)
   // More conservative approach for simulator
   #endif
   ```

## Environment

- Xcode 26.1 (build 24454)
- iOS 26.1 simulator (iPhone 17 Pro)
- Target: iOS 17.0+
- Language: Swift 6.0

## Question

Can you fix the SpeechRecognizer implementation to prevent the AVAudioEngine tap crash when using voice input multiple times across different questions?

The key issue seems to be that `inputNode.installTap()` throws "nullptr == Tap()" even though we're calling `removeTap(onBus: 0)` before installing a new tap.

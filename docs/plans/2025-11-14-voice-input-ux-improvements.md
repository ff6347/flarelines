# Voice Input UX Improvements

## Goal

Fix two UX issues with voice input to make it more intuitive and prevent data loss for users with chronic illness.

## Problems

1. **Live transcription in separate label** - Users must look away from the text field to see what's being transcribed, adding cognitive load
2. **Navigation unlocked during recording** - Users can switch questions mid-recording, causing transcript to go into wrong field

## Solution

### 1. Live Transcription in Text Field

**Behavior:**
- Show existing answer in normal black text
- Show live transcription appending in gray/secondary color
- When recording stops, gray text becomes black (committed)
- User sees exactly what they're saying in context

**Implementation:**
- Use `AttributedString` in TextEditor for two-tone display
- Display: `currentAnswer` (black) + `speechRecognizer.transcript` (gray)
- On stop: merge transcript into currentAnswer, clear SpeechRecognizer transcript
- Real-time updates via `@Published transcript` property

**Benefits:**
- No context switching between separate UI elements
- Clear visual distinction reduces confusion
- Immediate feedback without cognitive load
- Better for users with brain fog/fatigue

### 2. Lock Navigation During Recording

**Behavior:**
- While recording, Previous/Next buttons are disabled
- Same visual treatment as when buttons naturally disabled (gray)
- Must stop recording before navigating

**Implementation:**
```swift
Button(action: { viewModel.previousQuestion() }) {
    // ... button UI
}
.disabled(!viewModel.canGoPrevious || speechRecognizer.isRecording)

Button(action: { viewModel.nextQuestion() }) {
    // ... button UI
}
.disabled(!viewModel.canGoNext || speechRecognizer.isRecording)
```

**Benefits:**
- Prevents accidental data loss
- Clear cause and effect
- No surprising behavior or confirmation dialogs
- Matches existing disabled button pattern

## Technical Details

### Files to Modify

1. **ViewsLogView.swift**
   - Change TextEditor to show attributed text
   - Bind to both currentAnswer and speechRecognizer.transcript
   - Add `.disabled()` modifiers to navigation buttons
   - Remove separate transcription label

2. **UtilitiesSpeechRecognizer.swift**
   - No changes needed (already publishes transcript)

### AttributedString Approach

```swift
var displayText: AttributedString {
    var result = AttributedString(currentAnswer)
    result.foregroundColor = .primary

    if speechRecognizer.isRecording && !speechRecognizer.transcript.isEmpty {
        var transcriptAttr = AttributedString(speechRecognizer.transcript)
        transcriptAttr.foregroundColor = .secondary
        result.append(transcriptAttr)
    }

    return result
}
```

## User Flow

1. User taps mic button → Recording starts
2. As user speaks, gray text appears in text field
3. Navigation buttons gray out (locked)
4. User sees live transcription building in context
5. User taps mic button again → Recording stops
6. Gray text becomes black (committed)
7. Navigation buttons re-enable
8. User can edit or navigate to next question

## Edge Cases

- **User stops mid-word:** Transcript commits as-is (expected behavior)
- **Empty transcript:** No change to currentAnswer
- **Existing text:** Transcript appends with space separator
- **Multiple recordings:** Each adds to existing text

## Success Criteria

- Live transcription visible in text field (not separate label)
- Visual distinction between existing and transcribing text
- Cannot navigate while recording
- Transcript always goes into correct field
- No data loss on stop recording

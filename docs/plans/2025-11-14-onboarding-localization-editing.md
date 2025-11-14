# UX Improvements: Localization, Voice Input, Entry Editing, and Onboarding

## Overview

Four interconnected improvements to make Wolfsbit more accessible for German test groups and users with chronic illness.

## Implementation Order

### Priority 1: Localization Setup (String Catalogs)

**Goal:** Enable English/German support using iOS 17+ String Catalogs

**Why first:** Foundation for all other features. Build with localization from day one.

**Implementation:**
1. Create `Localizable.xcstrings` String Catalog in Xcode
2. Add German (de) as target language
3. Xcode auto-extracts all `Text("...")` strings from code
4. Export XLIFF for translation
5. Translate to German
6. Import translations back

**Code changes:**
- SwiftUI `Text("...")` automatically uses String Catalog
- For dynamic strings: `String(localized: "key")`
- Fallback to English for missing translations

**Validation:**
- Run app with device language = English → English UI
- Run app with device language = German → German UI
- Missing translations → fallback to English

---

### Priority 2: Voice Input UX Improvements

**Goal:** Make transcription clearer and prevent wrong-field errors

**Problem 1: Transcription in separate label**
- Current: Live transcription shows below mic button
- Issue: User must look away from text field
- Solution: Show live transcript directly in text field

**Problem 2: Can navigate while recording**
- Current: Previous/Next enabled during recording
- Issue: Transcript can end up in wrong question
- Solution: Disable navigation buttons while recording

**Implementation:**

**File: `wolfsbit/views/ViewsLogView.swift`**

Changes:
1. Remove separate transcription label (lines 112-117)
2. Update TextEditor to show AttributedString:
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
3. Update button stop logic to merge transcript:
   ```swift
   if speechRecognizer.isRecording {
       speechRecognizer.stopRecording()
       currentAnswer += (currentAnswer.isEmpty ? "" : " ") + speechRecognizer.transcript
       viewModel.updateAnswer(currentAnswer)
   }
   ```
4. Add `.disabled(speechRecognizer.isRecording)` to Previous/Next buttons

**Benefits:**
- See transcription in context
- Clear visual distinction (black vs gray text)
- Cannot navigate to wrong question
- Better for users with brain fog

---

### Priority 3: Entry Editing

**Goal:** Allow users to correct/update saved journal entries

**Current state:**
- Pencil icon exists in `JournalEntryCard`
- Button does nothing (line 106 in ViewsDataView.swift)

**Solution: Modal Edit Sheet**

**New File: `wolfsbit/views/ViewsEditEntryView.swift`**

Structure:
```swift
struct EditEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var entry: JournalEntry

    @State private var feeling: String
    @State private var painLevel: Int16
    @State private var symptoms: String
    @State private var notes: String

    var body: some View {
        NavigationView {
            Form {
                Section("Timestamp") {
                    Text(entry.timestamp, style: .date)
                    Text(entry.timestamp, style: .time)
                }

                Section("How are you feeling?") {
                    TextEditor(text: $feeling)
                        .frame(height: 100)
                }

                Section("Pain Level (0-10)") {
                    Stepper("\(painLevel)/10", value: $painLevel, in: 0...10)
                }

                Section("Symptoms") {
                    TextEditor(text: $symptoms)
                        .frame(height: 100)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }

                Section("Scores (Read-Only)") {
                    HStack {
                        Text("Heuristic Score")
                        Spacer()
                        Text(String(format: "%.1f", entry.heuristicScore))
                            .foregroundColor(.secondary)
                    }

                    if entry.mlScore > 0 {
                        HStack {
                            Text("ML Score")
                            Spacer()
                            Text(String(format: "%.1f", entry.mlScore))
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Active Score")
                        Spacer()
                        Text(String(format: "%.1f", entry.activeScore))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        // Update entry fields
        entry.feeling = feeling
        entry.painLevel = painLevel
        entry.symptoms = symptoms
        entry.notes = notes.isEmpty ? nil : notes

        // Recalculate heuristic score
        entry.heuristicScore = 10.0 - Double(painLevel)

        // Re-run ML scoring if available
        Task {
            let modelManager = MLModelManager.shared
            if modelManager.isModelAvailable {
                let input = modelManager.prepareInput(current: entry, context: viewContext)
                if let output = try? await modelManager.predict(input: input) {
                    modelManager.applyScore(to: entry, output: output, context: viewContext)
                }
            } else {
                // No ML model, use heuristic
                entry.activeScore = entry.heuristicScore
            }
        }

        try? viewContext.save()
    }
}
```

**Modified File: `wolfsbit/views/ViewsDataView.swift`**

Update pencil button in `JournalEntryCard`:
```swift
@State private var showingEditSheet = false

// ...

Button(action: {
    showingEditSheet = true
}) {
    Image(systemName: "pencil")
        .foregroundColor(.secondary)
        .font(.caption)
}
.sheet(isPresented: $showingEditSheet) {
    EditEntryView(entry: entry)
        .environment(\.managedObjectContext, viewContext)
}
```

**Validation:**
- Tap pencil icon → edit sheet opens
- Fields pre-populated with entry data
- Edit values, tap Save → entry updates
- Scores recalculate based on new pain level
- Chart reflects updated scores

---

### Priority 4: Onboarding System

**Goal:** First launch education + permission requests + Help reference

**Components:**

#### A. OnboardingView (New File)

**File: `wolfsbit/views/ViewsOnboardingView.swift`**

5-page TabView with page indicator:

**Page 1: Welcome**
```swift
VStack(spacing: 24) {
    Image(systemName: "heart.text.square.fill")
        .font(.system(size: 80))
        .foregroundColor(.red)

    Text("Welcome to Wolfsbit")
        .font(.largeTitle)
        .fontWeight(.bold)

    Text("Track your chronic illness symptoms with voice-first journaling. Designed for people with fatigue and brain fog.")
        .multilineTextAlignment(.center)
        .foregroundColor(.secondary)

    VStack(alignment: .leading, spacing: 12) {
        Label("Voice input for easy logging", systemImage: "mic.fill")
        Label("Daily health tracking", systemImage: "chart.line.uptrend.xyaxis")
        Label("Export reports for your doctor", systemImage: "doc.text.fill")
    }

    Button("Continue") {
        withAnimation {
            currentPage = 1
        }
    }
    .buttonStyle(.borderedProminent)
}
```

**Page 2: Voice Permissions**
```swift
VStack(spacing: 24) {
    Image(systemName: "mic.circle.fill")
        .font(.system(size: 80))
        .foregroundColor(.blue)

    Text("Voice Input Makes Logging Easy")
        .font(.title)
        .fontWeight(.bold)

    Text("Answer daily questions using your voice. Wolfsbit needs microphone and speech recognition access.")
        .multilineTextAlignment(.center)

    Text("Typing can be exhausting when you're fatigued. Voice input is faster and easier.")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)

    Button("Allow Microphone & Speech") {
        requestSpeechPermissions()
    }
    .buttonStyle(.borderedProminent)

    Button("I'll enable this later") {
        withAnimation {
            currentPage = 2
        }
    }
    .font(.subheadline)
}
```

**Page 3: Notifications**
**Page 4: ML Model (optional download)**
**Page 5: Ready to Start**

Full navigation with dots, back button, skip link.

#### B. HelpView Updates

**File: `wolfsbit/views/ViewsHelpView.swift`**

```swift
@State private var showingOnboarding = false

ScrollView {
    VStack(spacing: 20) {
        Button(action: {
            showingOnboarding = true
        }) {
            Label("Re-run Onboarding", systemImage: "arrow.clockwise")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }

        DisclosureGroup("About Wolfsbit") {
            Text("Wolfsbit helps you track your chronic illness...")
        }

        DisclosureGroup("Using Voice Input") {
            Text("Tap the microphone button to record...")
        }

        // ... more sections
    }
    .padding()
}
.sheet(isPresented: $showingOnboarding) {
    OnboardingView(isPresented: $showingOnboarding)
}
```

#### C. First Launch Detection

**File: `wolfsbit/wolfsbitApp.swift`**

```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
@State private var showOnboarding = false

var body: some Scene {
    WindowGroup {
        ContentView()
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .onAppear {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
    }
}
```

---

## Files Summary

### New Files
1. `Localizable.xcstrings` - String Catalog (created in Xcode)
2. `wolfsbit/views/ViewsOnboardingView.swift` - 5-page onboarding flow
3. `wolfsbit/views/ViewsEditEntryView.swift` - Entry editor modal

### Modified Files
1. `wolfsbit/wolfsbitApp.swift` - First launch onboarding trigger
2. `wolfsbit/views/ViewsLogView.swift` - Voice UX improvements + localization
3. `wolfsbit/views/ViewsDataView.swift` - Edit button functionality
4. `wolfsbit/views/ViewsHelpView.swift` - Reference content + re-run button
5. All existing views - Apply String Catalog localization

### Documentation
- `docs/plans/2025-11-14-voice-input-ux-improvements.md` (already created)
- `docs/plans/2025-11-14-onboarding-localization-editing.md` (this file)

---

## Testing Checklist

### Localization
- [ ] Device in English → app shows English
- [ ] Device in German → app shows German
- [ ] Missing translation → fallback to English works

### Voice Input
- [ ] Live transcription appears in text field (gray)
- [ ] Existing text stays black
- [ ] Stop recording → gray becomes black
- [ ] Cannot tap Previous/Next while recording
- [ ] Buttons re-enable after stop

### Entry Editing
- [ ] Tap pencil → edit sheet opens
- [ ] Fields pre-populated correctly
- [ ] Edit and save → entry updates
- [ ] Heuristic score recalculates
- [ ] ML score recalculates (if model available)
- [ ] Chart updates with new scores

### Onboarding
- [ ] First launch → onboarding shows
- [ ] Can skip pages
- [ ] Can go back
- [ ] Final page → sets hasCompletedOnboarding
- [ ] Help tab → can re-run onboarding
- [ ] Permissions request correctly
- [ ] ML download option shows/hides

---

## Success Criteria

✅ App available in English and German
✅ Voice transcription visible in text field with color distinction
✅ Navigation locked while recording
✅ Can edit saved entries
✅ Scores recalculate on edit
✅ Onboarding shows on first launch
✅ Can re-run onboarding from Help
✅ German test groups can use app in their language

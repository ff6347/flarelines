# Wolfsbit ML Integration Design

## Overview

Wolfsbit is a chronic illness journaling iOS app designed to help patients with conditions like lupus, fibromyalgia, and chronic fatigue syndrome document symptoms and provide actionable health reports to their doctors. The app uses a small language model with NLP capabilities to analyze patient input and generate health scores, while maintaining strict privacy (all data stays on-device) and ease of use (voice-first interface for patients experiencing fatigue or brain fog).

## Core Principles

1. **Privacy First** - Everything stays on the device. No cloud sync, no telemetry, no network calls (except TestFlight model updates).
2. **Ease of Use** - Frictionless logging for users with fatigue and brain fog. Voice-first interface, minimal questions.
3. **Medical Value** - Generate clear, concise reports doctors can understand in seconds.
4. **Offline Functionality** - App must work without internet connection.
5. **Adaptive Support** - Dynamic reminders based on patient state (flare-up vs. stable).

## System Architecture

### Three-Layer Architecture

```
┌─────────────────────────────────────────┐
│         INPUT LAYER                     │
│  (Voice-first symptom logging)          │
│                                         │
│  Voice → Speech Recognition → Text      │
│  ↓                                      │
│  Structured Fields (feeling, pain,      │
│  symptoms)                              │
│  ↓                                      │
│  Core Data (immediate save)             │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│         ANALYSIS LAYER                  │
│  (Dual scoring: Heuristic + ML)         │
│                                         │
│  Fetch: Current + Last 7 days entries   │
│  ↓                                      │
│  Heuristic Score: 10 - painLevel        │
│  ↓                                      │
│  Core ML Model Inference                │
│  ↓                                      │
│  If confidence ≥ threshold:             │
│    Use ML score + store confidence      │
│  If confidence < threshold:             │
│    Use heuristic + flag for review      │
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│         OUTPUT LAYER                    │
│  (Visualization + Export)               │
│                                         │
│  Swift Charts (real-time trends)        │
│  PDF Reports (for doctors)              │
│  CSV/XLSX Export (for analysis)         │
└─────────────────────────────────────────┘
```

### Data Flow

1. **Patient Logs Symptoms**
   - Opens app to LOG tab
   - Sees voice-first interface (large microphone button)
   - Answers 3 questions (for now - will validate with medical practitioners):
     - "How are you feeling today?" (free text)
     - "Describe your pain level" (free text, pain level extracted)
     - "Any symptoms you noticed?" (free text)
   - Entry saved immediately to Core Data

2. **Score Calculation**
   - Heuristic score calculated instantly: `healthScore = 10.0 - painLevel`
   - ML model fetches last 7 days of entries + current entry
   - Structured input prepared (see Model Input Format below)
   - Core ML runs inference locally
   - Model returns: `{score: Float, confidence: Float}`
   - Decision logic:
     ```swift
     if confidence >= CONFIDENCE_THRESHOLD {
         entry.mlScore = modelOutput.score
         entry.scoreConfidence = modelOutput.confidence
         entry.activeScore = entry.mlScore
     } else {
         entry.mlScore = nil
         entry.scoreConfidence = modelOutput.confidence
         entry.activeScore = entry.heuristicScore
         entry.needsReview = true
     }
     ```

3. **Visualization Update**
   - Chart refreshes with new data point
   - Low-confidence entries marked with visual indicator (icon/color)
   - User sees trends immediately

4. **Flare-Up Detection**
   - Automatic: Score drops 3+ points over 3 days, OR
   - Manual: User taps "I'm in a flare-up" button
   - App prompts: "How often should we remind you? 1x, 2x, or 3x daily?"
   - Reminder frequency adjusts accordingly

## Core ML Model Integration

### Model Input Format (Structured Fields)

The Core ML model receives structured input for each inference:

```swift
// Current entry
struct EntryInput {
    let feeling: String           // Free text
    let painLevel: Int            // 0-10 extracted from text
    let symptoms: String          // Free text
    let timestamp: Date
}

// Context: Last 7 days
struct ModelInput {
    let currentEntry: EntryInput
    let historicalEntries: [EntryInput]  // Up to 7 previous entries
}
```

### Model Output Format

```swift
struct ModelOutput {
    let score: Float              // Health score 0.0-10.0
    let confidence: Float         // Confidence 0.0-1.0
}
```

### Deployment Strategy

**TestFlight (Development):**
- Models stored in app documents directory
- Network endpoint checks for new model versions (WiFi only)
- Download new `.mlmodelc` bundle when available
- After download: re-score all historical entries in background
- Testers can compare: "Did v2 catch my flare-up earlier than v1?"
- UI shows model version in Settings

**Production (App Store):**
- Model bundled with app (`.mlmodelc` in app bundle)
- No network calls for model updates
- Updates only via App Store releases
- Simpler, more private, more stable
- Version locked per app release

### Handling Low Confidence

When `confidence < CONFIDENCE_THRESHOLD` (e.g., 0.6):
- Use heuristic score as fallback
- Mark entry with "needs review" flag
- Visual indicator in DATA view (icon or color change)
- Optional prompt: "Want to add more detail?" (non-blocking)
- In exports: clearly distinguish ML scores vs. heuristic scores

### Historical Re-scoring

When new model version downloaded (TestFlight only):
```swift
func rescore(withNewModel model: MLModel) async {
    let allEntries = fetchAllEntries()

    for entry in allEntries {
        let context = fetchContext(before: entry.timestamp, days: 7)
        let input = prepareModelInput(current: entry, history: context)
        let output = try? model.prediction(from: input)

        if let output = output {
            entry.mlScore = output.score
            entry.scoreConfidence = output.confidence
            if output.confidence >= CONFIDENCE_THRESHOLD {
                entry.activeScore = output.score
                entry.needsReview = false
            }
        }
    }

    saveContext()
}
```

## Core Data Model

### JournalEntry Entity (Updated)

```swift
@objc(JournalEntry)
public class JournalEntry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date

    // User input
    @NSManaged public var feeling: String?
    @NSManaged public var painLevel: Int16           // 0-10
    @NSManaged public var symptoms: String?

    // Scoring
    @NSManaged public var heuristicScore: Double     // 10 - painLevel
    @NSManaged public var mlScore: Double?           // ML model output (nil if not available)
    @NSManaged public var scoreConfidence: Double?   // ML confidence (nil if not available)
    @NSManaged public var activeScore: Double        // Currently displayed score
    @NSManaged public var needsReview: Bool          // True if confidence too low

    // User flags
    @NSManaged public var isFlaggedDay: Bool         // User marked as significant
    @NSManaged public var notes: String?             // Optional additional notes
}
```

### DoctorVisit Entity (New)

```swift
@objc(DoctorVisit)
public class DoctorVisit: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var visitDate: Date
    @NSManaged public var wasReportExported: Bool    // True if visit created from export
}
```

## User Interface Design

### Voice-First Logging Experience

**LOG View (Updated):**
- Large, prominent microphone button (primary action)
- Smaller text input button (secondary/fallback)
- Real-time transcription display
- Question progress: "Question 1 of 3"
- Auto-save on navigation (no explicit save needed until end)
- Navigation: Previous/Next buttons

**Visual Hierarchy:**
```
┌─────────────────────────────────────┐
│  Question 1 of 3                    │
│  ███████░░░ 70%                     │
├─────────────────────────────────────┤
│                                     │
│  How are you feeling today?         │
│                                     │
│  ┌───────────────────────────────┐ │
│  │                               │ │
│  │    [Transcribed text here]    │ │
│  │                               │ │
│  └───────────────────────────────┘ │
│                                     │
│         ┌─────────────┐             │
│         │             │             │
│         │   🎤 LARGE  │             │ <-- Primary
│         │   MIC BTN   │             │
│         └─────────────┘             │
│                                     │
│         [⌨️ Type instead]           │ <-- Secondary
│                                     │
├─────────────────────────────────────┤
│  [Previous]            [Next] →     │
└─────────────────────────────────────┘
```

### DATA View (Updated)

**Additions:**
- Visual indicators for low-confidence entries (icon on chart points)
- Flag/star icon on any entry (tap to mark as significant day)
- "Mark doctor visit" button at top
- When marking visit: simple date picker, saves to DoctorVisit entity

### Settings View (Updated)

**New Settings:**
- Current model version display (TestFlight only)
- "Check for model updates" button (TestFlight only)
- Flare-up status toggle: "I'm in a flare-up" / "I'm stable"
- Reminder frequency (auto-adjusts based on flare-up state)
- Confidence threshold slider (advanced, hidden by default)

## Dynamic Reminder System

### Flare-Up Detection Logic

**Automatic Detection:**
```swift
func detectFlareUp(for entries: [JournalEntry]) -> Bool {
    guard entries.count >= 3 else { return false }

    let sortedEntries = entries.sorted(by: { $0.timestamp > $1.timestamp })
    let recentThree = Array(sortedEntries.prefix(3))

    let firstScore = recentThree[0].activeScore
    let thirdScore = recentThree[2].activeScore

    // Score dropped 3+ points over 3 days
    return (thirdScore - firstScore) >= 3.0
}
```

**User Override:**
- Button in Settings or LOG view: "I'm in a flare-up"
- Tapping triggers prompt: "How often should we remind you?"
  - 1x daily (morning)
  - 2x daily (morning + evening)
  - 3x daily (morning + afternoon + evening)
- Choice saved to UserDefaults
- Reminders scheduled accordingly

**Return to Stable:**
- Automatic: Score stable or improving for 3+ days
- Manual: User taps "I'm feeling stable now" in Settings
- Prompt: "Great! We'll reduce reminders to once daily."

### Reminder Scheduling

```swift
enum ReminderFrequency {
    case onceDaily      // 9:00 AM
    case twiceDaily     // 9:00 AM, 8:00 PM
    case thriceDaily    // 9:00 AM, 2:00 PM, 8:00 PM
}

func scheduleReminders(frequency: ReminderFrequency) {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

    let times: [DateComponents] = switch frequency {
        case .onceDaily:
            [DateComponents(hour: 9)]
        case .twiceDaily:
            [DateComponents(hour: 9), DateComponents(hour: 20)]
        case .thriceDaily:
            [DateComponents(hour: 9), DateComponents(hour: 14), DateComponents(hour: 20)]
    }

    for time in times {
        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(/* ... */)
        UNUserNotificationCenter.current().add(request)
    }
}
```

## Export & Reporting

### Export Formats

**1. PDF Report (For Doctors)**

Structure:
```
┌────────────────────────────────────────┐
│ Wolfsbit Health Report                 │
│ Patient: [Name - optional]             │
│ Period: [Start Date] - [End Date]      │
│ Generated: [Today's Date]              │
├────────────────────────────────────────┤
│                                        │
│ HEALTH SCORE TREND                     │
│ [Chart: Line graph of scores over time]│
│                                        │
│ KEY METRICS                            │
│ • Average Health Score: 6.2            │
│ • Flare-up Episodes: 3                 │
│ • Average Pain Level: 4.8              │
│ • Stable Days: 21 / 30                 │
│                                        │
│ SIGNIFICANT EVENTS                     │
│ • Nov 5: Score dropped to 2.1 (severe) │
│ • Nov 12: User flagged day (fatigue)   │
│ • Nov 18: Score returned to baseline   │
│                                        │
│ DETAILED ENTRIES                       │
│ [Table of entries with dates, scores,  │
│  key symptoms, flagged days]           │
│                                        │
│ NOTES                                  │
│ • 3 entries marked for review (low     │
│   model confidence)                    │
│ • ML model version: 1.2                │
└────────────────────────────────────────┘
```

**2. CSV/XLSX Export (For Analysis)**

Columns:
- Date
- Timestamp
- Feeling (text)
- Pain Level (0-10)
- Symptoms (text)
- Heuristic Score
- ML Score (or blank if N/A)
- Confidence (or blank if N/A)
- Active Score
- Needs Review (boolean)
- User Flagged (boolean)
- Notes

**Aggregations Sheet (separate tab in XLSX):**
- Weekly averages
- Flare-up frequency
- Symptom word cloud data (top 20 words)
- Score distribution histogram data

### Export Workflow

**User Flow:**
1. Tap "Export Report" in Settings
2. Choose time range:
   - Last 7 days
   - Last 30 days
   - Last 90 days
   - Since last doctor visit (if visits tracked)
   - Custom date range
3. Choose format:
   - PDF (for doctor)
   - CSV
   - XLSX (with aggregations)
   - All formats
4. Tap "Generate"
5. Share sheet appears (email, files, print, etc.)
6. Prompt: "Did you have a doctor visit?" → Mark visit if yes

### Significant Changes Detection

**Automatic Highlighting:**
- Score drops of 3+ points over 3 days
- User-flagged days (star/flag icon)

**In PDF Report:**
- Highlighted in chart (different color markers)
- Listed in "Significant Events" section
- Annotated in detailed entries table

## Privacy & Security

### Data Storage

- All data in Core Data (SQLite on device)
- No iCloud sync (for v1 - may add opt-in later)
- No analytics frameworks
- No crash reporting services (use Xcode Organizer only)
- Speech recognition: prefer on-device when available

### Permissions Required

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Wolfsbit uses your microphone to record voice journal entries, making it easier to log symptoms when you're experiencing fatigue or brain fog.</string>

<key>NSSpeechRecognitionUsageDescription</key>
<string>Wolfsbit transcribes your voice into text for journal entries. All processing happens on your device when possible.</string>
```

### TestFlight Network Calls (Only)

- Model update check: `GET /api/models/latest`
- Model download: `GET /api/models/{version}.mlmodelc`
- Both over HTTPS only
- WiFi-only downloads (cellular check)
- User can disable in Settings

### Production (Zero Network)

- No network permissions in Info.plist
- App works in airplane mode
- All Core ML inference local
- No external dependencies

## Development Timeline Considerations

### Phase 1: UX Testing (Current)
- Use heuristic scoring (`10 - painLevel`)
- Test voice-first interface with target users
- Validate question set with medical practitioners
- Gather real patient journaling data
- Build export functionality

### Phase 2: ML Model Training
- Train model on collected real data
- Validate against medical expert assessment
- Test different model architectures (size vs. accuracy)
- Optimize for on-device inference speed
- Ensure model file size reasonable for app bundle

### Phase 3: TestFlight Integration
- Implement downloadable model architecture
- Add model version tracking
- Build re-scoring functionality
- Test with beta users on real flare-up data
- Iterate on confidence thresholds

### Phase 4: Production Release
- Bundle final model with app
- Remove network model update code
- Final privacy audit
- Ship to App Store

## Technical Constraints

### iOS Requirements
- iOS 17.0+ (for Swift Charts, modern SwiftUI)
- Core ML (iOS 11.0+, but using latest features)
- Speech framework (iOS 10.0+)

### Model Constraints
- File size: Target <10 MB for app bundle
- Inference time: <100ms for real-time feel
- Memory: <50 MB RAM during inference
- Context window: 7 entries × 3 fields = manageable input size

### Offline Requirements
- No required network calls in production
- All features work without connectivity
- Speech recognition graceful fallback (on-device preferred, server if needed during setup only)

## Open Questions for Medical Practitioner Validation

1. **Question Set**: Are 3 questions sufficient? Too many? Right questions?
2. **Score Interpretation**: Is 0-10 scale clear for doctors? Different scale better?
3. **Report Format**: What else should PDF report include? Lab results integration?
4. **Flare-Up Definition**: Is "3+ point drop over 3 days" medically meaningful?
5. **Visit Tracking**: Should we track doctor visit types (GP, specialist, ER)?

## Success Metrics

### For Patients
- Time to log entry: <60 seconds average (target: <30 seconds)
- Voice input success rate: >90%
- App abandonment rate: <20% after first week
- Days logged per week: >5 (engaged users)

### For Doctors
- Report comprehension time: <60 seconds
- Actionable insights found: >80% of reports
- Integration into clinical workflow: frictionless

### For ML Model
- Prediction accuracy vs. expert assessment: >85%
- Confidence calibration: high confidence = high accuracy
- Flare-up early detection: catch 2+ days before patient would report to doctor

## Future Enhancements (Out of Scope for v1)

- Medication tracking integration
- Photo attachments for rashes/swelling
- Multi-language support
- Apple Health integration (import sleep, activity data)
- iCloud sync (opt-in)
- Widget for quick logging
- Trend predictions ("flare-up likely in 2-3 days based on patterns")
- Customizable question sets
- Multiple patient profiles (for caregivers)

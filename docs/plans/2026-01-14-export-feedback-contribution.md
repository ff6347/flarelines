# Export, Feedback, and Data Contribution Design

## Overview

Three features that form a cohesive data system:

1. **CSV Export** - Local backup for users
2. **In-App Feedback** - Bug reports, feature requests, ML corrections
3. **Training Data Contribution** - Opt-in sharing to improve the model

## Key Design Decision

ML corrections happen naturally through the existing score flow. When `userScore != mlScore`, that entry contains implicit feedback. No extra UI friction needed.

## Data Contribution Payload

```json
{
  "text": "Journal entry text...",
  "mlScore": 1,
  "userScore": 2
}
```

No device ID, no timestamp, no identifiers. Both corrected and non-corrected entries are valuable:
- Corrected: training signal to fix mistakes
- Non-corrected: confirms model accuracy

## Score Flow Enhancement

### Current Flow
1. User enters text
2. User manually sets slider
3. ML scores separately (mlScore stored)

### New Flow
1. User finishes text entry
2. ML inference runs (async, ~1-2 sec)
3. Slider pre-fills with mlScore
4. User accepts or adjusts → becomes userScore
5. If different: visual indicator "Your score: 2 (AI suggested: 1)"

### Edge Cases
- Model not downloaded: slider defaults to middle, no ML suggestion
- Inference fails: silent fallback to manual entry

## Settings: Data Contribution

New section: "Help Improve Wolfsbit"

```
┌─────────────────────────────────────────┐
│ Help Improve Wolfsbit                   │
├─────────────────────────────────────────┤
│ ○ Contribute Data                [toggle]
│   Share journal entries anonymously     │
│   to help improve the AI scoring.       │
│                                         │
│   Learn more →                          │
└─────────────────────────────────────────┘
```

When toggled ON:
- Show explanation sheet (what's shared, what's not)
- Require explicit "I Agree" tap
- Store in `@AppStorage("contributeData")`

Privacy copy:
> "Help improve this research by sharing anonymized entries. Only journal text and scores are shared - no personal identifiers. This data supports academic research on AI-assisted health tracking."

## In-App Feedback

### General Feedback
Location: Settings → "Send Feedback"
- Text field for message
- Optional screenshot attachment
- Send via mailto:wolfsbit@inpyjamas.dev or backend endpoint

### ML Score Feedback
Handled by score flow - slider adjustment IS the feedback. No separate UI needed.

## CSV Export

Location: Settings → Data → Export Data

Format:
```csv
timestamp,journalText,userScore,mlScore
2026-01-14T10:30:00Z,"Woke up tired...",2,1
```

Flow:
1. Tap "Export Data"
2. Generate CSV in memory
3. Present iOS share sheet
4. User saves to Files, AirDrops, emails, etc.

## Data Contribution Backend

New field on JournalEntry: `isContributed: Bool` (default: false)

Flow:
1. User has "Contribute Data" ON
2. New entry saved
3. Upload to backend: {text, mlScore, userScore}
4. On success: mark isContributed = true
5. Never upload that entry again

For existing entries on first opt-in:
- Upload all where isContributed == false
- Mark each after success

## Onboarding Enhancement

New screen: "About This Project"

```
┌─────────────────────────────────────────┐
│         📚 Research Project             │
│                                         │
│  Wolfsbit is part of a master's thesis  │
│  exploring AI-assisted health           │
│  journaling.                            │
│                                         │
│  This is an academic project with no    │
│  commercial intent. Your data stays     │
│  on your device unless you choose to    │
│  contribute to the research.            │
│                                         │
│  [Learn More]        [Continue]         │
└─────────────────────────────────────────┘
```

## Schema Changes

### Remove (legacy, unused):
- `isFlaggedDay: Bool`
- `notes: String?`

### Add:
- `isContributed: Bool` (default: false)

Requires Core Data migration.

## Future: Personal Fine-Tuning

Since the model is small enough to run on-device, could fine-tune on user's own data for personalized scoring. Their writing style, their baseline. Design TBD.

## Implementation Phases

### Phase 1: Schema Cleanup
- Remove isFlaggedDay, notes from Core Data model
- Core Data migration
- Update views referencing these fields

### Phase 2: Score Flow Enhancement
- Run ML inference after text entry
- Pre-fill slider with mlScore
- Visual indicator when user adjusts
- Handle edge cases (no model, inference failure)

### Phase 3: CSV Export
- Generate CSV from all JournalEntry records
- Present via iOS share sheet
- Format: timestamp, journalText, userScore, mlScore

### Phase 4: Data Contribution Settings
- Add "Help Improve Wolfsbit" section to Settings
- Toggle + consent flow
- Store preference in @AppStorage

### Phase 5: Data Contribution Backend
- Add isContributed: Bool to schema
- Upload logic (when endpoint ready)
- Mark entries after successful upload
- Bulk upload on opt-in

### Phase 6: General Feedback
- "Send Feedback" button in Settings
- Simple mailto: or compose sheet

### Phase 7: Onboarding Enhancement
- Add "About This Project" screen
- Research/academic framing
- Data contribution preview

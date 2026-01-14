# Plan: iOS CoreData Schema Migration

**Status: COMPLETED**

## Summary

Simplify the JournalEntry schema to support the new single-field journal editor with user reference scores.

## Current Schema

```
JournalEntry:
  - id: UUID
  - timestamp: Date
  - feeling: String?          ← 3 separate inputs
  - painLevel: Int16          ←
  - symptoms: String?         ←
  - heuristicScore: Int16     ← complex scoring
  - mlScore: Int16            ←
  - scoreConfidence: Double   ←
  - activeScore: Int16        ←
  - needsReview: Bool         ←
  - notes: String?
  - isFlaggedDay: Bool
```

## New Schema

```
JournalEntry:
  - id: UUID
  - timestamp: Date
  - journalText: String       // Single diary text field
  - userScore: Int16          // User's reference score 0-3 (for evaluation)
  - mlScore: Int16            // Model output 0-3 (-1 = not scored)
  - notes: String?            // Keep
  - isFlaggedDay: Bool        // Keep
```

## Migration Strategy

### Option A: Lightweight Migration (Recommended)
- Create new model version in Xcode
- Add new attributes, mark old ones as optional
- Use mapping model for data transformation:
  - `journalText` = `feeling + " " + symptoms`
  - `userScore` = 0 (no prior user scores exist)
  - `mlScore` = -1 (needs scoring)
- Delete old attributes

### Option B: Fresh Start
- If app is pre-release with no real user data
- Just replace the schema, lose test data

## Changes

### 1. Create New Model Version
- In Xcode: Editor → Add Model Version
- Name: `wolfsbit_v2.xcdatamodel`
- Set as current version

### 2. Update JournalEntry Entity
In the new model version:
- Add `journalText: String` (optional for migration)
- Add `userScore: Integer 16` (default 0)
- Keep `mlScore: Integer 16` (default -1)
- Remove: `feeling`, `painLevel`, `symptoms`, `heuristicScore`, `scoreConfidence`, `activeScore`, `needsReview`

### 3. Update ModelsJournalEntry.swift
File: `wolfsbit/models/ModelsJournalEntry.swift`

```swift
@NSManaged public var journalText: String?
@NSManaged public var userScore: Int16       // 0-3
@NSManaged public var mlScore: Int16         // 0-3, -1 = not scored

// Remove old properties
```

### 4. Update Persistence.swift
File: `wolfsbit/Persistence.swift`

Ensure lightweight migration is enabled:
```swift
let description = NSPersistentStoreDescription()
description.shouldMigrateStoreAutomatically = true
description.shouldInferMappingModelAutomatically = true
```

### 5. Update DataView
File: `wolfsbit/views/ViewsDataView.swift`

- Change Y-axis from 0-10 to 0-3
- Show both userScore and mlScore
- Update JournalEntryCard display

### 6. Update EditEntryView
File: `wolfsbit/views/ViewsEditEntryView.swift`

- Show journalText (editable)
- Show userScore picker (0-3)
- Show mlScore (read-only)

## Files

**Modify:**
- `wolfsbit.xcdatamodeld/` (new version)
- `wolfsbit/models/ModelsJournalEntry.swift`
- `wolfsbit/Persistence.swift`
- `wolfsbit/views/ViewsDataView.swift`
- `wolfsbit/views/ViewsEditEntryView.swift`

## Dependencies

- Should be done AFTER or WITH UI redesign (UI expects new schema)

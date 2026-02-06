# Safe Core Data Persistence Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove destructive data deletion code and enable lightweight migration to prevent future data loss.

**Architecture:** Remove `deleteStoreIfIncompatible()` and related helper functions. Configure `NSPersistentContainer` to use lightweight migration. On any failure, crash to preserve data rather than silently delete.

**Tech Stack:** Swift, Core Data, NSPersistentContainer

---

## Task 1: Remove Destructive Code

**Files:**
- Modify: `flarelines/Persistence.swift:1-109`

**Step 1: Update ABOUTME comment**

Change lines 1-2 from:
```swift
// ABOUTME: CoreData persistence controller with store management.
// ABOUTME: Handles incompatible schema by wiping store (pre-release, no user data).
```

To:
```swift
// ABOUTME: CoreData persistence controller with lightweight migration.
// ABOUTME: Crashes on failure to preserve user data for recovery.
```

**Step 2: Remove call to deleteStoreIfIncompatible**

In the `init` method, remove lines 52-54:
```swift
        } else {
            // Pre-release: delete incompatible stores before loading
            Self.deleteStoreIfIncompatible()
        }
```

Replace with:
```swift
        } else {
            // Enable lightweight migration for schema changes
            let description = container.persistentStoreDescriptions.first
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true
        }
```

**Step 3: Delete helper functions**

Delete the following functions entirely:
- `deleteStoreIfIncompatible()` (lines 64-90)
- `defaultStoreURL()` (lines 92-95)
- `deleteStoreFiles(at:)` (lines 97-108)

**Step 4: Verify the file compiles**

Run: `xcodebuild -scheme Flarelines -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: Build succeeds with no errors related to Persistence.swift

**Step 5: Commit**

```bash
git add flarelines/Persistence.swift
git commit -m "fix(persistence): remove destructive data deletion

Remove deleteStoreIfIncompatible() which was silently deleting user
data on schema mismatches. Enable lightweight migration instead.
Crashes on failure to preserve data for recovery.

BREAKING: Apps with incompatible schemas will now crash instead of
losing data. This is intentional - data preservation over silent loss."
```

---

## Task 2: Verify Final Implementation

**Files:**
- Read: `flarelines/Persistence.swift`

**Step 1: Verify final file structure**

The file should now be approximately 60 lines and contain:
1. ABOUTME comments (2 lines)
2. Import statement
3. `PersistenceController` struct with:
   - `shared` static property
   - `preview` static property with sample data
   - `container` property
   - `init(inMemory:)` method with lightweight migration config

**Step 2: Verify no delete-related code remains**

Run: `grep -n "delete\|Delete\|wipe\|Wipe" flarelines/Persistence.swift`

Expected: No output (no delete-related code)

**Step 3: Verify migration options are set**

Run: `grep -n "shouldMigrateStoreAutomatically\|shouldInferMappingModelAutomatically" flarelines/Persistence.swift`

Expected: Both options appear set to `true`

**Step 4: Run full build**

Run: `xcodebuild -scheme Flarelines -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

---

## Expected Final Persistence.swift

```swift
// ABOUTME: CoreData persistence controller with lightweight migration.
// ABOUTME: Crashes on failure to preserve user data for recovery.

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let calendar = Calendar.current
        let sampleEntries: [(text: String, userScore: Int16, mlScore: Int16)] = [
            ("Heute geht es mir gut. Keine besonderen Symptome, nur leichte Müdigkeit am Nachmittag.", 0, 0),
            ("Kopfschmerzen seit dem Aufwachen. Habe Ibuprofen genommen.", 1, 1),
            ("Starke Gelenkschmerzen, konnte kaum aufstehen. Termin beim Arzt gemacht.", 2, 2),
            ("Schub - musste im Bett bleiben. Fieber und extreme Erschöpfung.", 3, 3),
            ("Besser als gestern. Noch müde aber keine Schmerzen mehr.", 1, 1),
            ("Guter Tag! Sport gemacht und mich danach gut gefühlt.", 0, 0),
            ("Leichte Symptome am Morgen, aber im Laufe des Tages besser geworden.", 1, -1),
            ("Hautausschlag bemerkt. Dokumentiere für den nächsten Arztbesuch.", 2, -1),
        ]

        for (index, entry) in sampleEntries.enumerated() {
            let journalEntry = JournalEntry(context: viewContext)
            journalEntry.id = UUID()
            journalEntry.timestamp = calendar.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            journalEntry.journalText = entry.text
            journalEntry.userScore = entry.userScore
            journalEntry.mlScore = entry.mlScore
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "flarelines")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable lightweight migration for schema changes
            let description = container.persistentStoreDescriptions.first
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
```

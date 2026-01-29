# Multiple Reminders with Day-of-Week Selection

## Summary

Extend the reminder system to support multiple reminders per day, each with individual weekday selection (e.g., Mon/Wed/Fri only).

## Data Model

Store reminders as JSON in UserDefaults (not Core Data - simpler, sufficient for settings data).

**New types in `/workspace/flarelines/models/ModelsReminder.swift`:**

```swift
struct Reminder: Codable, Identifiable, Equatable {
    let id: UUID
    var time: Date              // hour/minute only
    var isEnabled: Bool
    var weekdays: Set<Weekday>  // which days to fire
}

enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4
    case thursday = 5, friday = 6, saturday = 7
}
```

**Storage key:** `reminders_v2` (JSON-encoded `[Reminder]`)

## ReminderScheduler Changes

Rewrite `/workspace/flarelines/utilities/UtilitiesReminderScheduler.swift`:

| Old API | New API |
|---------|---------|
| `scheduleDaily(at:)` | `scheduleAllReminders([Reminder])` |
| `cancelReminder()` | `cancelAllReminders()` |
| - | `cancelReminder(Reminder)` |
| - | `cancelLegacyReminder()` (migration) |

**Notification ID format:** `reminder-{UUID}-{weekday}` (e.g., `reminder-abc123-2` for Monday)

Each reminder creates one `UNCalendarNotificationTrigger` per selected weekday with `repeats: true`.

## UI Design

Replace the notification section in SettingsView with a new `ReminderSection`:

```
Section: "Reminders"
├── Toggle: "Enable Reminders" (master switch)
└── [If enabled]
    ├── Reminder rows (time, weekday summary, individual toggle)
    ├── Swipe to delete
    └── "+ Add Reminder" button
```

**ReminderDetailView** (presented as sheet):
- Time picker (wheel style)
- Weekday picker (7 circular toggle buttons: M T W T F S S)
- Quick buttons: "Every Day", "Weekdays"
- Delete button

**New file:** `/workspace/flarelines/views/ViewsReminderSection.swift`

## Migration

In `flarelinesApp.swift init()`:
1. Check if `reminders_v2` key exists (already migrated)
2. If not, read legacy `dailyReminderTime` and `notificationsEnabled`
3. Create one `Reminder` with all weekdays selected
4. Save to new format, cancel legacy `"daily-reminder"` notification

## Files to Change

| File | Action |
|------|--------|
| `flarelines/models/ModelsReminder.swift` | **Create** - Reminder, Weekday types |
| `flarelines/views/ViewsReminderSection.swift` | **Create** - ReminderSection, ReminderRow, ReminderDetailView, WeekdayPicker |
| `flarelines/utilities/UtilitiesReminderScheduler.swift` | **Rewrite** - multi-reminder API |
| `flarelines/views/ViewsSettingsView.swift` | **Modify** - replace notification section with ReminderSection() |
| `flarelines/flarelinesApp.swift` | **Modify** - add migration, update rescheduleRemindersIfEnabled() |
| `flarelines/Localizable.xcstrings` | **Modify** - add weekday names, UI labels (EN + DE) |

## Localization Strings to Add

- Weekday short names: Sun, Mon, Tue, Wed, Thu, Fri, Sat
- Weekday full names: Sunday, Monday, etc.
- UI: "Every day", "Weekdays", "Weekends", "Add Reminder", "Edit Reminder", "Delete Reminder", "Repeat", "Enable Reminders"

## Verification

1. **Fresh install:** Enable reminders, add 2-3 with different times and weekday selections
2. **Migration:** Test with existing single reminder enabled, verify it converts to new format with all days selected
3. **Notifications:** On device, verify notifications fire at correct times on correct days
4. **Edge cases:** No weekdays selected (should not schedule), all reminders disabled, permission denied flow
5. **Localization:** Switch to German, verify all strings display correctly

## Limits

- iOS allows 64 pending notifications per app
- Each reminder = up to 7 notifications (one per weekday)
- Recommend max 10 reminders in UI

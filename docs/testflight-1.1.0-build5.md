# Flarelines v1.1.0 (Build 5) - TestFlight Notes

## Critical Fix

**Data Loss Bug Fixed** - Previous builds (1-4) had a bug that could delete all journal entries when updating from v1.0.x. This is now fixed. Your data is safe.

If you lost data after updating to an earlier 1.1.0 build, unfortunately that data cannot be recovered. We sincerely apologize for this issue.

---

## What to Test

### 1. Data Preservation (Most Important)
- [ ] If you have existing entries from v1.0.x, verify they are still present after updating
- [ ] Create new entries and verify they persist after app restart
- [ ] Edit an existing entry and verify changes are saved

### 2. Chart Features (New in 1.1.0)
- [ ] **Drag to select range**: On the chart, drag horizontally to select a custom date range
- [ ] **Tap entry point**: Tap a data point on the chart to highlight that entry in the list
- [ ] **"All" time range**: New option to view your complete history
- [ ] **Sticky chart**: Chart stays visible while scrolling through entries
- [ ] **Clear selection**: Use the "Clear" button to reset chart selection

### 3. General Functionality
- [ ] Create a new journal entry with text
- [ ] Use voice input to dictate an entry
- [ ] Rate your flare level (0-3 slider)
- [ ] View your data in the chart
- [ ] Export data to CSV (Settings)
- [ ] Switch between English and German

---

## New Features in v1.1.0

- **Chart drag-to-select**: Select a custom date range by dragging on the chart
- **"All" time range option**: View your complete journal history
- **Improved chart interaction**: Tap data points to jump to entries
- **Sticky chart header**: Chart stays visible while scrolling entries
- **German translation**: Clear button now localized

## Bug Fixes in v1.1.0

- Fixed chart timeframe switching
- Fixed chart selection persistence
- Fixed tap target size on chart
- Fixed journal entries header (now sticky)
- **Fixed critical data loss on app update** (Build 5)

---

## Known Issues

- Reminders are not working (will be fixed in future update)
- Log view may show stale data after editing (refresh by switching tabs)

---

## Feedback

Please report any issues or feedback through TestFlight or GitHub Issues.

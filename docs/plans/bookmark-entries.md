# Bookmark/Highlight Journal Entries

**Beads**: wolfsbit-15g
**Goal**: Let users bookmark entries they want to discuss with their doctor, making them easy to find across months of data.

## User Story

As a patient preparing for a medical appointment, I want to flag specific journal entries so I can quickly find and reference them during my visit, without scrolling through months of entries.

## Design

### Core Data Model Change

Add `isBookmarked` (Boolean, default NO) to `JournalEntry` entity. Lightweight migration handles this automatically since it's a new optional attribute with a default value.

### UI Touchpoints

1. **Entry list** (ViewsDataView.swift - JournalEntryCard)
   - Bookmark icon visible on bookmarked entries
   - Swipe action or long-press to toggle bookmark

2. **Chart** (ViewsDataView.swift - HealthProgressChart)
   - Bookmarked entries get a distinct marker (e.g. star or different color PointMark)
   - Visible at a glance when scanning the timeline

3. **Filter toggle** (ViewsDataView.swift - Journal Entries header area)
   - Toggle/button to show only bookmarked entries
   - Clear indication of active filter

4. **Edit view** (ViewsEditEntryView.swift)
   - Bookmark toggle available when editing an entry

### Files to Change

- `flarelines.xcdatamodeld` - Add `isBookmarked` attribute
- `ModelsJournalEntry.swift` - Add `isBookmarked` property
- `ViewsDataView.swift` - Chart markers, list indicators, filter toggle
- `ViewsEditEntryView.swift` - Bookmark toggle in edit mode
- `UtilitiesSampleDataGenerator.swift` - Optionally bookmark some sample entries
- `UtilitiesCSVExporter.swift` - Include bookmark status in exports
- `Localizable.xcstrings` - New strings for bookmark UI

### Open Questions

- Icon choice: bookmark, star, pin, or flag? (bookmark feels most natural for "save for later review")
- Should bookmarks be exportable in the doctor visit report / PDF export?
- Should there be a dedicated "Bookmarked" tab or just a filter toggle in the existing data view?

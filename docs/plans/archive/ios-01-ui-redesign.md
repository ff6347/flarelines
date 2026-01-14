# Plan: iOS UI Redesign - Full-Screen Journal Editor

## Summary

Redesign the wolfsbit iOS app from tab-based navigation to a full-screen journal editor inspired by iOS Journal and Drafts apps.

## Design Reference

See sketches in `docs/design/`:
- `sketch-ui-activity-input.png` - Activity/score rating screen
- `sketch-ui-text-input.png` - Text diary entry screen

## Layout

**Two screens/states:**

### Screen 1: Activity Rating
```
┌─────────────────────────────────┐
│                          [✓]   │  ← Save button (pink checkmark)
├─────────────────────────────────┤
│ Rate your activity!             │  ← Header
│ ●───────────────────────────    │  ← Score slider
│ 0        1        2        3    │
├─────────────────────────────────┤
│                                 │
│         (empty area)            │
│                                 │
├─────────────────────────────────┤
│ [🎤] [📊] [?] [⚙] [⊠]          │  ← Toolbar
├─────────────────────────────────┤
│        Keyboard                 │
└─────────────────────────────────┘
```

### Screen 2: Text Entry
```
┌─────────────────────────────────┐
│                          [✓]   │  ← Save button (pink checkmark)
├─────────────────────────────────┤
│ How are you doing today?        │  ← Header
│ ─────────────────────────────── │
│ Start writing...                │  ← Text editor
│                                 │
│                                 │
├─────────────────────────────────┤
│ [🎤] [📊] [?] [⚙] [⊠]          │  ← Toolbar
├─────────────────────────────────┤
│        Keyboard                 │
└─────────────────────────────────┘
```

**Flow:** Sequential two-step entry (swipeable):
1. **Step 1**: Write diary entry (text/voice)
2. **Step 2**: Rate your activity (slider 0-3)
3. **Save**: Checkmark saves both and triggers ML scoring

**Navigation:** Horizontal swipe between steps (like `TabView` with `.tabViewStyle(.page)`)

**Toolbar buttons (left to right):**
1. **Mic** (🎤) - Voice input mode
2. **Data** (📊) - Opens DataView as sheet
3. **Help** (?) - Opens HelpView as sheet
4. **Settings** (⚙) - Opens SettingsView as sheet
5. **Dismiss** (⊠) - Dismiss keyboard

## UI Elements

Use iOS native components:
- `Slider` with discrete steps (0, 1, 2, 3) and tick marks
- Standard SF Symbols for toolbar icons
- Native keyboard toolbar (`.toolbar { ToolbarItemGroup(placement: .keyboard) }`)
- Pink/mauve accent color for save checkmark

## User Flow

### Step 1: Write Entry (default screen)
- User sees text editor with "How are you doing today?"
- Can type OR tap mic for voice input
- **Voice mode**: Keyboard hidden, mic visualization, live transcription
- **Keyboard mode**: Standard text entry
- Swipe left to go to Step 2

### Step 2: Rate Activity
- User sees slider with 0-1-2-3 scale
- "Rate your activity!" header
- Drag slider to select score
- Tap checkmark to save

### Navigation
- **Swipe left/right** between steps (TabView page style)
- Page indicator dots show current step (optional)
- Checkmark always visible - saves at any point
- Toolbar provides access to Data/Help/Settings via sheets
- Dismiss keyboard before swiping (or auto-dismiss on swipe attempt)

## Changes

### 1. Rewrite LogView → JournalEditorView
File: `wolfsbit/views/ViewsLogView.swift`

- Remove 3-question wizard
- Full-screen TextEditor
- Header with score picker (0-3) + save button
- Custom keyboard toolbar
- `@FocusState` to control keyboard
- Voice mode hides keyboard

```swift
struct JournalEditorView: View {
    @State private var journalText = ""
    @State private var userScore: Int = 1
    @State private var isVoiceMode = false
    @FocusState private var isEditorFocused: Bool

    @State private var showingHelp = false
    @State private var showingData = false
    @State private var showingSettings = false
}
```

### 2. Update ContentView
File: `wolfsbit/ContentView.swift`

- Remove TabView
- JournalEditorView as root view
- Other views accessed via sheets

### 3. Update Existing Views for Sheet Presentation
- `ViewsDataView.swift` - add dismiss button for sheet
- `ViewsHelpView.swift` - add dismiss button for sheet
- `ViewsSettingsView.swift` - add dismiss button for sheet

### 4. Delete Unused Code
- Remove tab bar code from ContentView
- Delete `ModelsHealthQuestion.swift` (no more 3-question flow)

## Files

**Modify:**
- `wolfsbit/views/ViewsLogView.swift` (major rewrite)
- `wolfsbit/ContentView.swift` (remove TabView)
- `wolfsbit/views/ViewsDataView.swift` (sheet presentation)
- `wolfsbit/views/ViewsHelpView.swift` (sheet presentation)
- `wolfsbit/views/ViewsSettingsView.swift` (sheet presentation)
- `wolfsbit/views/ViewModelsJournalViewModel.swift` (simplify)

**Delete:**
- `wolfsbit/models/ModelsHealthQuestion.swift`

## Dependencies

- None - can be done independently
- Should be done BEFORE CoreData migration (UI expects new schema)

# Design Implementation Guide

This document maps your design sketches to the implemented code.

## LOG View Design Mapping

### Your Design Elements → Code Implementation

1. **Top Navigation Tabs** (LOG | DATA | HELP | Settings)
   - **File:** `ContentView.swift`
   - **Code:** `TabView` with 4 tabs
   - Each tab has a label and icon

2. **Question Progress** ("Question 1 of 3")
   - **File:** `Views/LogView.swift`
   - **Code:** Lines showing current question index
   - Progress bar shows completion percentage

3. **Progress Bar** (horizontal indicator)
   - **File:** `Views/LogView.swift`
   - **Code:** `ProgressView(value: viewModel.progress)`
   - Updates as you move through questions

4. **Question Card** (black background with question text)
   - **File:** `Views/LogView.swift`
   - **Code:** Text view with black background
   - Font: `.title2` with `.semibold` weight

5. **Text Input Area** (large text field with placeholder)
   - **File:** `Views/LogView.swift`
   - **Code:** `TextEditor` with custom styling
   - Placeholder: "Type your answer or use voice input..."
   - Height: 200 points

6. **Voice Input Button** (microphone icon)
   - **File:** `Views/LogView.swift`
   - **Code:** Button with `Image(systemName: "mic")`
   - Changes to red when recording
   - Integrates with `SpeechRecognizer`

7. **Navigation Buttons** (Previous | Next)
   - **File:** `Views/LogView.swift`
   - **Code:** HStack with two buttons
   - Previous: Gray outline button
   - Next/Save: Black filled button
   - Next becomes "Save" on last question

## DATA View Design Mapping

### Your Design Elements → Code Implementation

1. **Health Progress Chart**
   - **File:** `Views/DataView.swift`
   - **Code:** Swift `Chart` with `LineMark` and `PointMark`
   - Shows health scores over time
   - Y-axis: 0-10 scale
   - X-axis: Date labels

2. **Time Range Selector** (7D | 30D | 90D | 180D | 1Y)
   - **File:** `Views/DataView.swift`
   - **Code:** HStack of buttons
   - Selected: Black background with white text
   - Unselected: Clear background
   - Filters chart data based on selection

3. **Journal Entries Section**
   - **File:** `Views/DataView.swift`
   - **Code:** ScrollView with grouped entries
   - Icon: "book" symbol
   - Title: "Journal Entries"

4. **Date Headers** (black bars with date)
   - **File:** `Views/DataView.swift`
   - **Code:** `GroupedEntry` structure
   - Black background, white text
   - Format: "Monday, November 10, 2025"

5. **Entry Cards** (individual journal entries)
   - **File:** `Views/DataView.swift`
   - **Component:** `JournalEntryCard`
   - Shows:
     - Time stamp (01:00 AM)
     - Question 1: How are you feeling?
     - Question 2: Pain level (X/10)
     - Question 3: Symptoms
   - Edit button in top-right corner

## Color Scheme

The app uses a neutral/monochrome design:

```swift
Primary Background: System grouped background (light gray)
Card Background: System background (white)
Accent: Black
Text: Primary (black) and Secondary (gray)
Recording: Red
```

## Typography Scale

```swift
Navigation Titles: .largeTitle
Question Text: .title2 .semibold
Body Text: .body
Secondary Info: .caption
```

## Spacing System

```swift
xs:  4pt
sm:  8pt
md:  12pt
lg:  16pt
xl:  24pt
xxl: 32pt
```

## Component Dimensions

```swift
Text Editor Height: 200pt
Chart Height: 200pt
Button Height: ~50pt (with padding)
Card Padding: 16pt
Border Radius: 8-12pt
```

## Making Your Own Customizations

### Change Colors

Edit `Utilities/DesignTokens.swift`:

```swift
enum Colors {
    static let accent = Color.blue  // Change from black
    static let recordingActive = Color.red
    // ... etc
}
```

### Adjust Question Text

Edit `Models/HealthQuestion.swift`:

```swift
static let defaultQuestions: [HealthQuestion] = [
    HealthQuestion(
        id: 1,
        text: "Your custom question here?",
        placeholder: "Your placeholder...",
        type: .text
    ),
    // Add more questions...
]
```

### Modify Layout Spacing

Edit spacing values in `LogView.swift` or `DataView.swift`:

```swift
VStack(spacing: 24) {  // Change this number
    // ...
}
```

### Update Chart Appearance

Edit `DataView.swift` chart configuration:

```swift
Chart {
    ForEach(filteredEntries) { entry in
        LineMark(...)
            .interpolationMethod(.catmullRom)  // Try .linear or .monotone
            .foregroundStyle(Color.blue)  // Change line color
        
        PointMark(...)
            .symbolSize(50)  // Change point size
    }
}
.chartYScale(domain: 0...10)  // Adjust scale
```

### Change Font Weights

Throughout the views, modify font modifiers:

```swift
.font(.title2)      // Change size
.fontWeight(.bold)  // Change weight
```

## Icon Reference

All icons use SF Symbols:

| Element | Icon Name |
|---------|-----------|
| LOG Tab | `pencil.circle.fill` |
| DATA Tab | `chart.line.uptrend.xyaxis` |
| HELP Tab | `questionmark.circle.fill` |
| Settings | `gearshape.fill` |
| Microphone | `mic` or `mic.fill` |
| Edit | `pencil` |
| Health | `heart.fill` |
| Calendar | `calendar` |
| Book | `book` |

## Animation & Transitions

The app uses SwiftUI's default animations:

```swift
withAnimation {
    // State changes
}
```

Add custom animations:

```swift
.animation(.spring(response: 0.3), value: someState)
```

## Accessibility

All views support:
- Dynamic Type (text scaling)
- VoiceOver labels
- High contrast mode
- Reduced motion

Test with accessibility settings enabled on your device.

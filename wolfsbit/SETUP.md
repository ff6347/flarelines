# Xcode Setup Checklist

Follow these steps to get your Wolfsbit app running in Xcode:

## 1. Add Files to Xcode Project

All the Swift files have been created, but you need to add them to your Xcode project:

1. In Xcode, right-click on your project navigator
2. Select "Add Files to wolfsbit..."
3. Add each of these files/folders:
   - `Models/` folder
   - `ViewModels/` folder  
   - `Views/` folder
   - `Utilities/` folder

Make sure "Copy items if needed" and "Add to targets: wolfsbit" are checked.

## 2. Update Core Data Model

**Critical Step:** Your app currently has an `Item` entity. You need to add the new `JournalEntry` entity:

### Method 1: Using Xcode's Data Model Editor
1. Open `wolfsbit.xcdatamodeld` in Xcode
2. Click the "+" button at the bottom to add a new entity
3. Name it: `JournalEntry`
4. Add these attributes (click "+" in the Attributes section):

| Attribute Name | Type | Optional |
|---------------|------|----------|
| id | UUID | No |
| timestamp | Date | No |
| feeling | String | Yes |
| painLevel | Integer 16 | No |
| symptoms | String | Yes |
| healthScore | Double | No |

5. In the Data Model Inspector (right panel):
   - Set "Codegen" to "Manual/None"
   - Set "Class" to "JournalEntry"
   - Set "Module" to "Current Product Module"

6. You can optionally delete the old `Item` entity if you don't need it

## 3. Update Info.plist

Add privacy descriptions for microphone and speech recognition:

1. Open your `Info.plist` file
2. Add these two entries (right-click → Add Row):

**NSMicrophoneUsageDescription**
```
Wolfsbit needs microphone access to record your journal entries using voice input.
```

**NSSpeechRecognitionUsageDescription**
```
Wolfsbit uses speech recognition to transcribe your voice into text for journal entries.
```

Alternatively, in the Info tab of your target:
- Click "+" on Custom iOS Target Properties
- Type "Privacy - Microphone Usage Description"
- Enter the description
- Repeat for "Privacy - Speech Recognition Usage Description"

## 4. Update Build Settings (if needed)

If you get any import errors, make sure:
- iOS Deployment Target is set to iOS 17.0 or later
- Swift Language Version is Swift 5.9 or later

## 5. Build and Run

1. Select your target device or simulator
2. Press Cmd+B to build
3. Fix any remaining errors (usually just path issues)
4. Press Cmd+R to run

## Common Issues & Solutions

### "Cannot find 'JournalEntry' in scope"
- Make sure you've added the JournalEntry entity to Core Data
- Set Codegen to "Manual/None"
- Clean build folder (Cmd+Shift+K)

### "Module 'Speech' not found"
- The Speech framework is automatically available on iOS
- Make sure you're building for an iOS target

### Voice input not working
- Check Info.plist has the privacy descriptions
- Grant permissions when the app asks
- Voice recognition requires iOS 10.0+

### Charts not displaying
- Swift Charts requires iOS 16.0+
- Make sure your deployment target is high enough

### Preview crashes
- Core Data previews can be tricky
- Try running on simulator instead of relying on previews
- Check that PersistenceController.preview is set up correctly

## Testing the App

### Test LOG View
1. Open app to LOG tab
2. Answer the first question
3. Tap "Voice Input" to test speech recognition
4. Grant permissions if prompted
5. Speak your answer
6. Tap Next to proceed through all 3 questions
7. Tap Save on the last question

### Test DATA View
1. Switch to DATA tab
2. Verify your entry appears in the list
3. Check that the chart shows your health score
4. Try different time range filters (7D, 30D, etc.)
5. Add more entries to see the chart populate

### Test Voice Recognition
1. Grant microphone permission in Settings if needed
2. Grant speech recognition permission when prompted
3. Tap microphone button in LOG view
4. Speak clearly
5. Watch for live transcription below the button
6. Tap microphone again to stop

## Next Steps

Once everything is working:

1. **Customize Questions**: Edit `HealthQuestion.swift` to add your own questions
2. **Adjust UI**: Modify colors and styling to match your design preferences  
3. **Add Features**: Implement export, notifications, or additional tracking metrics
4. **Test on Device**: Deploy to a physical device for real-world testing

## File Structure Reference

Your project should look like this in Xcode:

```
wolfsbit
├── wolfsbitApp.swift
├── ContentView.swift
├── Persistence.swift
├── Models
│   ├── JournalEntry.swift
│   └── HealthQuestion.swift
├── ViewModels
│   └── JournalViewModel.swift
├── Views
│   ├── LogView.swift
│   ├── DataView.swift
│   ├── HelpView.swift
│   └── SettingsView.swift
├── Utilities
│   └── SpeechRecognizer.swift
├── wolfsbit.xcdatamodeld
│   └── wolfsbit.xcdatamodel
│       ├── Item (optional - can delete)
│       └── JournalEntry (NEW - you need to add this)
└── Assets.xcassets
```

## Need Help?

If you encounter issues:
1. Clean Build Folder: Cmd+Shift+K
2. Restart Xcode
3. Check all imports are correct
4. Verify Info.plist has privacy descriptions
5. Make sure Core Data model has JournalEntry entity with correct attributes

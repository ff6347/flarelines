# Quick Start Guide - Wolfsbit

## ⚡️ 5-Minute Setup

### 1. Core Data Model (2 minutes)
Open `wolfsbit.xcdatamodeld` and add:

**New Entity: JournalEntry**
```
✓ id (UUID)
✓ timestamp (Date)
✓ feeling (String, Optional)
✓ painLevel (Integer 16)
✓ symptoms (String, Optional)
✓ healthScore (Double)
```

Set Codegen to: **Manual/None**

### 2. Info.plist (1 minute)
Add two keys:

```
Privacy - Microphone Usage Description
"Wolfsbit needs microphone access to record your journal entries."

Privacy - Speech Recognition Usage Description
"Wolfsbit uses speech recognition to transcribe your voice into text."
```

### 3. Add Files to Project (1 minute)
Drag these folders into Xcode:
- Models/
- Views/
- ViewModels/
- Utilities/

Check: "Copy items if needed" ✓

### 4. Build & Run (1 minute)
```
Clean: Cmd+Shift+K
Build: Cmd+B
Run: Cmd+R
```

## ✅ Quick Test

1. Open LOG tab
2. Answer question 1
3. Tap Next → Answer question 2
4. Tap Next → Answer question 3
5. Tap Save
6. Switch to DATA tab
7. See your entry!

## 🧪 Generate Test Data

Settings → Debug Controls → "Generate 30 Days"

## 📱 App Structure

```
LOG     → Create new entries
DATA    → View chart & history
HELP    → Documentation
Settings → Configure app
```

## 🎤 Voice Input

1. Tap microphone button
2. Grant permissions (first time)
3. Speak your answer
4. Tap microphone again to stop
5. Edit text if needed

## 🎯 Three Questions

1. How are you feeling today?
2. Describe your pain level (0-10)
3. Any symptoms you noticed?

## 🐛 Common Issues

**Won't build?**
→ Check Core Data entity exists
→ Clean build folder

**Voice not working?**
→ Check Info.plist
→ Grant permissions
→ Try on real device

**No chart data?**
→ Add entries via LOG
→ Or generate sample data

## 📄 Documentation

- **SETUP.md** - Detailed setup
- **DESIGN.md** - Customization
- **README.md** - Full docs
- **IMPLEMENTATION_SUMMARY.md** - Complete overview

## 🎨 Customize

**Colors:** `Utilities/DesignTokens.swift`
**Questions:** `Models/HealthQuestion.swift`
**Layout:** Individual view files

## 💾 Files Created

✓ 4 Models
✓ 4 Views  
✓ 1 ViewModel
✓ 3 Utilities
✓ 4 Documentation files
✓ Updated 2 core files

Total: 18 files ready to use!

---

**That's it!** You now have a complete chronic illness journaling app. 🎉

Follow SETUP.md for any issues.

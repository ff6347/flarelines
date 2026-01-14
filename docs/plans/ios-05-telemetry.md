# Plan: iOS Telemetry with TelemetryDeck

## Summary

Add privacy-focused analytics using TelemetryDeck (Germany-based) to track app usage, installs, and model downloads. No prompt/diary content tracking.

## Why TelemetryDeck

- **German company** - GDPR compliant, EU data residency
- **Privacy-first** - No IP logging, hashed user IDs, no tracking
- **iOS-native** - Swift SDK, SwiftUI support
- **Free tier** - 100k signals/month (sufficient for initial launch)
- **Automatic insights** - Sessions, retention, device info built-in

## Events to Track

| Event | When | Purpose |
|-------|------|---------|
| `app.installed` | First launch ever | Install count |
| `app.session` | Each app open | Daily active users (automatic) |
| `model.downloadStarted` | User taps download | Download funnel |
| `model.downloadCompleted` | Download succeeds | Success rate |
| `model.downloadFailed` | Download fails | Error tracking |
| `entry.saved` | Journal entry saved | Feature usage |
| `onboarding.completed` | Onboarding finished | Onboarding funnel |

**NOT tracked:**
- Journal text content
- User scores
- Any personal health data

## Changes

### 1. Add TelemetryDeck Package

In Xcode: File → Add Packages → `https://github.com/TelemetryDeck/SwiftSDK`
- Dependency Rule: Up to Next Major Version
- Add to target: wolfsbit

### 2. Create Analytics Service
File: `wolfsbit/services/ServicesAnalytics.swift`

```swift
// ABOUTME: Wrapper around TelemetryDeck for app analytics.
// ABOUTME: Privacy-focused - no personal data or diary content tracked.

import TelemetryDeck

enum Analytics {
    static func configure() {
        let config = TelemetryDeck.Config(appID: "<APP-ID-FROM-DASHBOARD>")
        TelemetryDeck.initialize(config: config)
    }

    // MARK: - App Lifecycle

    static func trackInstall() {
        // Only send once ever
        let key = "hasTrackedInstall"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        TelemetryDeck.signal("app.installed")
        UserDefaults.standard.set(true, forKey: key)
    }

    static func trackOnboardingCompleted() {
        TelemetryDeck.signal("onboarding.completed")
    }

    // MARK: - Model

    static func trackModelDownloadStarted() {
        TelemetryDeck.signal("model.downloadStarted")
    }

    static func trackModelDownloadCompleted() {
        TelemetryDeck.signal("model.downloadCompleted")
    }

    static func trackModelDownloadFailed(error: String) {
        TelemetryDeck.signal("model.downloadFailed", parameters: ["error": error])
    }

    // MARK: - Usage

    static func trackEntrySaved() {
        TelemetryDeck.signal("entry.saved")
    }
}
```

### 3. Initialize in App Entry Point
File: `wolfsbit/wolfsbitApp.swift`

```swift
import SwiftUI

@main
struct wolfsbitApp: App {
    init() {
        Analytics.configure()
        Analytics.trackInstall()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 4. Add Tracking Calls

**OnboardingView** - after completing onboarding:
```swift
Analytics.trackOnboardingCompleted()
```

**ModelDownloader** - in download methods:
```swift
func downloadModel() async throws {
    Analytics.trackModelDownloadStarted()
    do {
        // ... download logic
        Analytics.trackModelDownloadCompleted()
    } catch {
        Analytics.trackModelDownloadFailed(error: error.localizedDescription)
        throw error
    }
}
```

**JournalEditorView** - on save:
```swift
func saveEntry() {
    // ... save logic
    Analytics.trackEntrySaved()
}
```

## Setup Steps

1. Create TelemetryDeck account at https://dashboard.telemetrydeck.com
2. Create new app, get App ID
3. Add App ID to `ServicesAnalytics.swift`
4. (Optional) Add App ID to build config for dev/prod separation

## Files

**Add:**
- `wolfsbit/services/ServicesAnalytics.swift`

**Modify:**
- `wolfsbit/wolfsbitApp.swift` (init analytics)
- `wolfsbit/views/ViewsOnboardingView.swift` (track completion)
- `wolfsbit/services/ServicesModelDownloader.swift` (track downloads)
- `wolfsbit/views/ViewsLogView.swift` or JournalEditorView (track saves)

## Dependencies

- None - can be done anytime
- Best done AFTER UI redesign (to track correct save flow)

## Cost

- **Free tier**: 100k signals/month
- **Indie tier**: €4/month for 500k signals (if needed)

## Privacy Compliance

TelemetryDeck is designed for GDPR/privacy compliance:
- No IP address logging
- User IDs are double-hashed (client + server)
- No cross-app tracking
- German data residency
- No consent banner required (no cookies, no tracking)

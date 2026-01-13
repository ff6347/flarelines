// ABOUTME: Analytics configuration using TelemetryDeck for privacy-focused usage tracking.
// ABOUTME: Provides a simple interface to initialize analytics and send custom signals.

import TelemetryDeck

enum Analytics {
    private static let appID = "8E98BDBF-A5FC-497E-955D-AB5306278CA8"

    /// Initialize TelemetryDeck analytics. Call once at app startup.
    static func initialize() {
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
    }

    /// Send a custom signal for tracking specific user actions.
    /// - Parameter name: A descriptive name for the action (e.g., "journalEntryCreated")
    static func signal(_ name: String) {
        TelemetryDeck.signal(name)
    }

    /// Send a custom signal with additional parameters.
    /// - Parameters:
    ///   - name: A descriptive name for the action
    ///   - parameters: Additional context (keys and values are anonymized)
    static func signal(_ name: String, parameters: [String: String]) {
        TelemetryDeck.signal(name, parameters: parameters)
    }
}

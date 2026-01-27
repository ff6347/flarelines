// ABOUTME: UIApplicationDelegate for handling background URLSession events.
// ABOUTME: Stores completion handlers for background downloads and coordinates with ModelDownloader.

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    /// Completion handlers for background URL sessions, keyed by session identifier
    static var backgroundCompletionHandlers: [String: () -> Void] = [:]

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        AppDelegate.backgroundCompletionHandlers[identifier] = completionHandler
    }
}

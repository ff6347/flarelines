// ABOUTME: Main entry point for the flarelines iOS app.
// ABOUTME: Configures CoreData persistence, localization, and AppDelegate for background downloads.

import SwiftUI
import CoreData

@main
struct flarelinesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared

    init() {
        Analytics.initialize()
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            LocalizedRootView(
                hasCompletedOnboarding: $hasCompletedOnboarding,
                showOnboarding: $showOnboarding
            )
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
            .onAppear {
                if !hasCompletedOnboarding {
                    showOnboarding = true
                }
            }
            .task {
                await Self.rescheduleRemindersIfEnabled()
            }
        }
    }

    /// Reschedules daily reminders if notifications are enabled.
    /// This ensures reminders stay synchronized after app updates or time changes.
    private static func rescheduleRemindersIfEnabled() async {
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        guard notificationsEnabled else { return }

        let reminderTimeInterval = UserDefaults.standard.double(forKey: "dailyReminderTime")
        let reminderTime: Date
        if reminderTimeInterval > 0 {
            reminderTime = Date(timeIntervalSince1970: reminderTimeInterval)
        } else {
            // Default to current time if not set
            reminderTime = Date()
        }

        await ReminderScheduler.shared.scheduleDaily(at: reminderTime)
    }
}

/// Wrapper view that observes language preference and applies locale environment.
struct LocalizedRootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Binding var showOnboarding: Bool

    var body: some View {
        ContentView()
            .environment(\.locale, LanguagePreference.shared.locale)
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
                    .environment(\.locale, LanguagePreference.shared.locale)
            }
    }
}

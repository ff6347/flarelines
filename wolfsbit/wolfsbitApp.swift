// ABOUTME: Main entry point for the wolfsbit iOS app.
// ABOUTME: Configures CoreData persistence, localization, and AppDelegate for background downloads.

import SwiftUI
import CoreData

@main
struct wolfsbitApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared

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
        }
    }
}

/// Wrapper view that observes language preference and applies locale environment.
struct LocalizedRootView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Binding var showOnboarding: Bool
    var languagePreference = LanguagePreference.shared

    var body: some View {
        ContentView()
            .environment(\.locale, languagePreference.locale)
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
                    .environment(\.locale, languagePreference.locale)
            }
    }
}

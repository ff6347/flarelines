// ABOUTME: App settings for notifications, data management, and debug tools.
// ABOUTME: Provides daily reminder configuration and data export/clear options.

import SwiftUI

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("dailyReminderTime") private var dailyReminderTime = Date()
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Daily Reminders", isOn: $notificationsEnabled)
                
                if notificationsEnabled {
                    DatePicker("Reminder Time",
                             selection: $dailyReminderTime,
                             displayedComponents: .hourAndMinute)
                }
            }
            
            Section("Data") {
                Button("Export Data") {
                    // Export functionality
                }
                
                Button("Clear All Data", role: .destructive) {
                    // Clear data functionality
                }
            }
            
            #if DEBUG
            Section("Debug Tools") {
                NavigationLink("Debug Controls") {
                    DebugControlsView()
                }
            }
            #endif
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}

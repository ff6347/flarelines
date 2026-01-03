// ABOUTME: App settings for notifications, data management, and debug tools.
// ABOUTME: Provides daily reminder configuration and data export/clear options.

import SwiftUI
import UIKit

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

                Button("Print Corner Radii") {
                    printAllCornerRadii()
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

// MARK: - Debug Helper

#if DEBUG
func printAllCornerRadii() {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
        print("Could not find window")
        return
    }

    print("\n========== CORNER RADII SCAN ==========")
    scanCornerRadii(view: window, depth: 0)
    print("========================================\n")
}

private func scanCornerRadii(view: UIView, depth: Int) {
    let indent = String(repeating: "  ", count: depth)
    let viewType = String(describing: type(of: view))

    if view.layer.cornerRadius > 0 {
        print("\(indent)\(viewType): cornerRadius = \(view.layer.cornerRadius)")
    }

    for subview in view.subviews {
        scanCornerRadii(view: subview, depth: depth + 1)
    }
}
#endif

// ABOUTME: App settings for notifications, data management, and debug tools.
// ABOUTME: Provides daily reminder configuration and data export/clear options.

import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("dailyReminderTime") private var dailyReminderTime = Date()

    @State private var cornerRadiusResult: String = ""
    @State private var showingRadiusAlert = false

    var body: some View {
        List {
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

                Button("Scan Corner Radii") {
                    scanAndShowCornerRadii()
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
        .listStyle(.plain)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Corner Radii Found", isPresented: $showingRadiusAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(cornerRadiusResult)
        }
    }

    #if DEBUG
    private func scanAndShowCornerRadii() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                cornerRadiusResult = "No window found"
                showingRadiusAlert = true
                return
            }

            var found: [CGFloat: Int] = [:]
            scanCornerRadiiForAlert(view: window, depth: 0, maxDepth: 10, results: &found)

            var resultText = ""
            for (radius, count) in found.sorted(by: { $0.key > $1.key }) {
                resultText += "\(radius) pt: \(count) views\n"
            }

            if resultText.isEmpty {
                resultText = "No corner radii found"
            }

            cornerRadiusResult = resultText
            showingRadiusAlert = true
        }
    }

    private func scanCornerRadiiForAlert(view: UIView, depth: Int, maxDepth: Int, results: inout [CGFloat: Int]) {
        guard depth < maxDepth else { return }

        if view.layer.cornerRadius > 0 {
            let radius = view.layer.cornerRadius
            results[radius, default: 0] += 1
        }

        for subview in view.subviews {
            scanCornerRadiiForAlert(view: subview, depth: depth + 1, maxDepth: maxDepth, results: &results)
        }
    }
    #endif
}

#Preview {
    NavigationView {
        SettingsView()
    }
}

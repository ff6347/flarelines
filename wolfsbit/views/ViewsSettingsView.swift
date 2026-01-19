// ABOUTME: App settings for notifications and data management.
// ABOUTME: Provides daily reminder configuration, ML model download, and data export/clear options.

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("dailyReminderTime") private var dailyReminderTime = Date()
    @AppStorage("contributeData") private var contributeData = false

    @State private var showingPermissionDeniedAlert = false
    @State private var showingConsentSheet = false
    @State private var pendingContributeToggle = false

    var body: some View {
        List {
            ModelDownloadSection()

            Section("Notifications") {
                Toggle("Daily Reminders", isOn: Binding(
                    get: { notificationsEnabled },
                    set: { newValue in
                        if newValue {
                            requestNotificationPermission()
                        } else {
                            notificationsEnabled = false
                        }
                    }
                ))

                if notificationsEnabled {
                    DatePicker("Reminder Time",
                             selection: $dailyReminderTime,
                             displayedComponents: .hourAndMinute)
                }
            }
            .alert("Notifications Disabled", isPresented: $showingPermissionDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("To enable reminders, please allow notifications in Settings.")
            }
            
            Section("Data") {
                Button("Export Data") {
                    // Export functionality
                }

                Button("Clear All Data", role: .destructive) {
                    // Clear data functionality
                }
            }

            Section {
                Toggle("Contribute Data", isOn: Binding(
                    get: { contributeData },
                    set: { newValue in
                        if newValue && !contributeData {
                            pendingContributeToggle = true
                            showingConsentSheet = true
                        } else {
                            contributeData = newValue
                        }
                    }
                ))

                Text("Share journal entries anonymously to help improve the AI scoring.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Link("Learn more", destination: URL(string: "https://wolfsbit.inpyjamas.dev/research")!)
                    .font(.caption)
            } header: {
                Text("Help Improve Wolfsbit")
            } footer: {
                Text("This is a master's research project. No commercial use.")
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Link("Privacy Policy", destination: URL(string: "https://wolfsbit.inpyjamas.dev/privacy")!)
                Link("Terms of Service", destination: URL(string: "https://wolfsbit.inpyjamas.dev/terms")!)
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
        .sheet(isPresented: $showingConsentSheet, onDismiss: {
            if pendingContributeToggle && !contributeData {
                pendingContributeToggle = false
            }
        }) {
            DataContributionConsentSheet(isPresented: $showingConsentSheet) {
                contributeData = true
                pendingContributeToggle = false
            }
        }
    }

    private func requestNotificationPermission() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()

            switch settings.authorizationStatus {
            case .authorized, .provisional:
                // Already authorized
                await MainActor.run {
                    notificationsEnabled = true
                }
            case .notDetermined:
                // Request permission
                do {
                    let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                    await MainActor.run {
                        notificationsEnabled = granted
                        if !granted {
                            showingPermissionDeniedAlert = true
                        }
                    }
                } catch {
                    await MainActor.run {
                        notificationsEnabled = false
                    }
                }
            case .denied:
                // Previously denied - show settings prompt
                await MainActor.run {
                    showingPermissionDeniedAlert = true
                }
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}

// MARK: - Model Download Section

struct ModelDownloadSection: View {
    private var downloader = ModelDownloader.shared
    @State private var modelInfo: ModelInfo?
    @State private var isModelDownloaded = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showDeleteConfirmation = false

    var body: some View {
        Section("ML Model") {
            if isLoading {
                HStack {
                    ProgressView()
                    Text("Checking model status...")
                        .foregroundStyle(.secondary)
                }
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                Button("Retry") {
                    Task { await loadModelStatus() }
                }
            } else if let info = modelInfo {
                modelInfoView(info)
            } else {
                Text("No model available")
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            await loadModelStatus()
        }
    }

    @ViewBuilder
    private func modelInfoView(_ info: ModelInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(info.id)
                .font(.headline)
            Text("Version \(info.version) • \(info.formattedSize)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if downloader.isDownloading {
            downloadProgressView
        } else if downloader.canResume {
            pausedDownloadView
        } else if isModelDownloaded {
            downloadedView(info)
        } else {
            downloadButton(info)
        }
    }

    private var downloadProgressView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: downloader.downloadProgress)
            HStack {
                Text(formatBytes(downloader.bytesDownloaded))
                Text("/")
                Text(formatBytes(downloader.totalBytes))
                Spacer()
                Text("\(Int(downloader.downloadProgress * 100))%")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Button("Pause") {
                    downloader.pauseDownload()
                }

                Button("Cancel", role: .destructive) {
                    downloader.cancelDownload()
                }
            }
        }
    }

    private var pausedDownloadView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "pause.circle.fill")
                    .foregroundStyle(.orange)
                Text("Download Paused")
                Spacer()
                Text("\(Int(downloader.downloadProgress * 100))%")
            }
            .font(.subheadline)

            HStack {
                Button("Resume") {
                    Task { try? await downloader.resumeDownload() }
                }

                Button("Cancel", role: .destructive) {
                    downloader.cancelDownload()
                }
            }
        }
    }

    @ViewBuilder
    private func downloadedView(_ info: ModelInfo) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text("Downloaded")
                .foregroundStyle(.secondary)
        }

        Button("Delete Model", role: .destructive) {
            showDeleteConfirmation = true
        }
        .confirmationDialog(
            "Delete ML Model?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task { await deleteModel(info) }
            }
        } message: {
            Text("You'll need to download the model again to use automatic scoring.")
        }
    }

    private func downloadButton(_ info: ModelInfo) -> some View {
        Button {
            Task { await downloadModel(info) }
        } label: {
            HStack {
                Image(systemName: "arrow.down.circle")
                Text("Download Model")
            }
        }
    }

    // MARK: - Actions

    private func loadModelStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            modelInfo = try await ManifestFetcher.shared.currentModel()
            if let info = modelInfo {
                isModelDownloaded = await ModelStorage.shared.modelExists(filename: info.filename)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func downloadModel(_ info: ModelInfo) async {
        guard let downloadURL = URL(string: info.downloadUrl) else { return }

        do {
            let destination = try await ModelStorage.shared.modelPath(for: info.filename)
            try await downloader.downloadModel(
                from: downloadURL,
                to: destination,
                expectedSHA256: info.sha256
            )
            isModelDownloaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteModel(_ info: ModelInfo) async {
        do {
            try await ModelStorage.shared.deleteModel(filename: info.filename)
            isModelDownloaded = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

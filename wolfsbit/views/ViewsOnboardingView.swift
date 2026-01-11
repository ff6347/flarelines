// ABOUTME: First-launch onboarding flow explaining app purpose and requesting permissions.
// ABOUTME: 5-page TabView with progress dots, can be re-shown from Help tab.

import SwiftUI
import Speech
import UserNotifications

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var currentPage = 0
    @State private var speechRecognizer = SpeechRecognizer()

    // Language preference
    var languagePreference = LanguagePreference.shared

    // ML Model download state
    private let downloader = ModelDownloader.shared
    @State private var modelInfo: ModelInfo?
    @State private var isModelDownloaded = false
    @State private var downloadError: String?

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                welcomePage
                    .tag(0)

                // Page 2: Voice Permissions
                voicePermissionsPage
                    .tag(1)

                // Page 3: Notifications
                notificationsPage
                    .tag(2)

                // Page 4: ML Model
                mlModelPage
                    .tag(3)

                // Page 5: Ready
                readyPage
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip button
            VStack {
                HStack {
                    Spacer()

                    if currentPage < 4 {
                        Button("Skip") {
                            currentPage = 4
                        }
                        .font(DesignTokens.Typography.body)
                        .padding()
                    }
                }
                Spacer()
            }
        }
        .interactiveDismissDisabled()
    }

    // MARK: - Page 1: Welcome

    private var welcomePage: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: DesignTokens.Dimensions.heroIconSize))
                .foregroundColor(DesignTokens.Colors.highlight)

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Welcome to Wolfsbit")
                    .font(DesignTokens.Typography.title)
                    .fontWeight(DesignTokens.Weight.strong)
                    .multilineTextAlignment(.center)

                Text("Track your chronic illness symptoms with voice-first journaling. Designed for people with fatigue and brain fog.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Label("Voice input for easy logging", systemImage: "mic.fill")
                    .font(DesignTokens.Typography.subheading)

                Label("Daily health tracking", systemImage: "cylinder.split.1x2")
                    .font(DesignTokens.Typography.subheading)

                Label("Export reports for your doctor", systemImage: "doc.text.fill")
                    .font(DesignTokens.Typography.subheading)
            }
            .frame(maxWidth: DesignTokens.Dimensions.contentMaxWidth)

            // Language picker
            languagePicker

            Spacer()

            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                Text("Continue")
                    .fontWeight(DesignTokens.Weight.emphasis)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.Colors.highlight)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
    }

    // MARK: - Language Picker

    private var languagePicker: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            ForEach(AppLanguage.allCases) { language in
                Button(action: {
                    languagePreference.language = language
                }) {
                    Text(language.displayName)
                        .font(DesignTokens.Typography.body)
                        .fontWeight(languagePreference.language == language ? DesignTokens.Weight.emphasis : .regular)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(
                            languagePreference.language == language
                                ? DesignTokens.Colors.highlight.opacity(0.2)
                                : Color.clear
                        )
                        .foregroundColor(
                            languagePreference.language == language
                                ? DesignTokens.Colors.highlight
                                : .secondary
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md, style: .continuous)
                                .stroke(
                                    languagePreference.language == language
                                        ? DesignTokens.Colors.highlight
                                        : Color.secondary.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Page 2: Voice Permissions

    private var voicePermissionsPage: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: DesignTokens.Dimensions.heroIconSize))
                .foregroundColor(DesignTokens.Colors.highlight)

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Voice Input Makes Logging Easy")
                    .font(DesignTokens.Typography.heading)
                    .fontWeight(DesignTokens.Weight.emphasis)
                    .multilineTextAlignment(.center)

                Text("Answer daily questions using your voice. Wolfsbit needs microphone and speech recognition access.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)

                Text("Typing can be exhausting when you're fatigued. Voice input is faster and easier.")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Button(action: {
                    requestSpeechPermissions()
                }) {
                    Text("Allow Microphone & Speech")
                        .fontWeight(DesignTokens.Weight.emphasis)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.highlight)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
                }

                Button("I'll enable this later") {
                    withAnimation {
                        currentPage = 2
                    }
                }
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
    }

    // MARK: - Page 3: Notifications

    private var notificationsPage: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            Image(systemName: "bell.circle.fill")
                .font(.system(size: DesignTokens.Dimensions.heroIconSize))
                .foregroundColor(DesignTokens.Colors.highlight)

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Daily Reminders (Optional)")
                    .font(DesignTokens.Typography.heading)
                    .fontWeight(DesignTokens.Weight.emphasis)
                    .multilineTextAlignment(.center)

                Text("Get reminded to log your symptoms. You can adjust frequency during flare-ups.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)

                Text("Consistent tracking helps you and your doctor see patterns.")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                Button(action: {
                    requestNotificationPermissions()
                }) {
                    Text("Enable Reminders")
                        .fontWeight(DesignTokens.Weight.emphasis)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.highlight)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
                }

                Button("Skip for now") {
                    withAnimation {
                        currentPage = 3
                    }
                }
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
    }

    // MARK: - Page 4: ML Model

    private var mlModelPage: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: DesignTokens.Dimensions.heroIconSize))
                .foregroundColor(DesignTokens.Colors.highlight)

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Smart Health Scoring")
                    .font(DesignTokens.Typography.heading)
                    .fontWeight(DesignTokens.Weight.emphasis)
                    .multilineTextAlignment(.center)

                Text("Download the AI model that analyzes your entries and provides health scores. This is a research project—the model is required.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)

                VStack(spacing: DesignTokens.Spacing.sm) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.secondary)
                        Text("Runs on your device")
                            .font(DesignTokens.Typography.body)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.secondary)
                        Text("Your data stays private")
                            .font(DesignTokens.Typography.body)
                        Spacer()
                    }

                    if let info = modelInfo {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.secondary)
                            Text("Download: \(info.formattedSize)")
                                .font(DesignTokens.Typography.body)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)

                // Download progress - always reserve space to prevent layout shift
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ProgressView(value: downloader.downloadProgress)
                    HStack {
                        Text(formatBytes(downloader.bytesDownloaded))
                        Text("/")
                        Text(formatBytes(downloader.totalBytes))
                        Spacer()
                        Text("\(Int(downloader.downloadProgress * 100))%")
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
                .opacity(downloader.isDownloading ? 1 : 0)

                if let error = downloadError {
                    Text(error)
                        .font(DesignTokens.Typography.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, DesignTokens.Spacing.xxl)
                }
            }

            Spacer()

            VStack(spacing: DesignTokens.Spacing.lg) {
                if isModelDownloaded {
                    // Already downloaded
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Model Downloaded")
                    }
                    .font(DesignTokens.Typography.body)

                    Button(action: {
                        withAnimation { currentPage = 4 }
                    }) {
                        Text("Continue")
                            .fontWeight(DesignTokens.Weight.emphasis)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.Colors.highlight)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
                    }
                } else if downloader.isDownloading {
                    // Download in progress
                    Button(action: {
                        withAnimation { currentPage = 4 }
                    }) {
                        Text("Continue (Download in Background)")
                            .fontWeight(DesignTokens.Weight.emphasis)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.Colors.highlight)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
                    }
                } else if downloader.canResume {
                    // Download paused - show resume option
                    HStack {
                        Image(systemName: "pause.circle.fill")
                            .foregroundStyle(.orange)
                        Text("Download Paused (\(Int(downloader.downloadProgress * 100))%)")
                    }
                    .font(DesignTokens.Typography.body)

                    Button(action: {
                        Task { try? await downloader.resumeDownload() }
                    }) {
                        Text("Resume Download")
                            .fontWeight(DesignTokens.Weight.emphasis)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.Colors.highlight)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
                    }
                } else {
                    // Not started
                    Button(action: {
                        startModelDownload()
                    }) {
                        Text("Download Model")
                            .fontWeight(DesignTokens.Weight.emphasis)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.Colors.highlight)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
        .task {
            await loadModelInfo()
        }
    }

    // MARK: - Page 5: Ready

    private var readyPage: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: DesignTokens.Dimensions.heroIconSize))
                .foregroundColor(DesignTokens.Colors.highlight)

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("You're All Set!")
                    .font(DesignTokens.Typography.title)
                    .fontWeight(DesignTokens.Weight.strong)

                Text("Start by logging how you're feeling today. Your first entry takes less than a minute.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if speechRecognizer.authorizationStatus == .authorized {
                    Label("Voice input enabled", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else {
                    Label("Voice input not configured", systemImage: "mic.slash")
                        .foregroundColor(.secondary)
                }

                // ML model status
                if isModelDownloaded {
                    Label("Model ready", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if downloader.isDownloading {
                    HStack {
                        Label("Downloading model...", systemImage: "arrow.down.circle")
                        Text("\(Int(downloader.downloadProgress * 100))%")
                    }
                    .foregroundColor(.orange)
                } else {
                    Label("Model download pending", systemImage: "arrow.down.circle")
                        .foregroundColor(.secondary)
                }
            }
            .font(DesignTokens.Typography.body)

            Spacer()

            Button(action: {
                completeOnboarding()
            }) {
                Text("Start Journaling")
                    .fontWeight(DesignTokens.Weight.emphasis)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.Colors.highlight)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
            }
            .padding(.horizontal, DesignTokens.Spacing.xxl)
            .padding(.bottom, DesignTokens.Spacing.huge)
        }
    }

    // MARK: - Permission Requests

    private func requestSpeechPermissions() {
        Task {
            await speechRecognizer.requestAuthorization()

            // Auto-advance if permissions granted
            if speechRecognizer.authorizationStatus == .authorized {
                await MainActor.run {
                    withAnimation {
                        currentPage = 2
                    }
                }
            }
        }
    }

    private func requestNotificationPermissions() {
        Task {
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await MainActor.run {
                    if granted {
                        withAnimation {
                            currentPage = 3
                        }
                    }
                }
            } catch {
                print("Error requesting notification permissions: \(error)")
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
        isPresented = false
    }

    // MARK: - ML Model Helpers

    private func loadModelInfo() async {
        do {
            modelInfo = try await ManifestFetcher.shared.currentModel()
            if let info = modelInfo {
                isModelDownloaded = await ModelStorage.shared.modelExists(filename: info.filename)
            }
        } catch {
            downloadError = error.localizedDescription
        }
    }

    private func startModelDownload() {
        guard let info = modelInfo, let downloadURL = URL(string: info.downloadUrl) else {
            return
        }

        Task {
            do {
                let destination = try await ModelStorage.shared.modelPath(for: info.filename)
                try await downloader.downloadModel(
                    from: downloadURL,
                    to: destination,
                    expectedSHA256: info.sha256
                )
                isModelDownloaded = true
            } catch {
                downloadError = error.localizedDescription
            }
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}

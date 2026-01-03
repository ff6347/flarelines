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
                        .font(DesignTokens.Typography.secondary)
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
                    .font(DesignTokens.Typography.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Track your chronic illness symptoms with voice-first journaling. Designed for people with fatigue and brain fog.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                Label("Voice input for easy logging", systemImage: "mic.fill")
                    .font(DesignTokens.Typography.headline)

                Label("Daily health tracking", systemImage: "cylinder.split.1x2")
                    .font(DesignTokens.Typography.headline)

                Label("Export reports for your doctor", systemImage: "doc.text.fill")
                    .font(DesignTokens.Typography.headline)
            }
            .frame(maxWidth: DesignTokens.Dimensions.contentMaxWidth)

            Spacer()

            Button(action: {
                withAnimation {
                    currentPage = 1
                }
            }) {
                Text("Continue")
                    .fontWeight(.semibold)
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

    // MARK: - Page 2: Voice Permissions

    private var voicePermissionsPage: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: DesignTokens.Dimensions.heroIconSize))
                .foregroundColor(DesignTokens.Colors.highlight)

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Voice Input Makes Logging Easy")
                    .font(DesignTokens.Typography.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Answer daily questions using your voice. Wolfsbit needs microphone and speech recognition access.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)

                Text("Typing can be exhausting when you're fatigued. Voice input is faster and easier.")
                    .font(DesignTokens.Typography.secondary)
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
                        .fontWeight(.semibold)
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
                .font(DesignTokens.Typography.secondary)
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
                    .font(DesignTokens.Typography.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Get reminded to log your symptoms. You can adjust frequency during flare-ups.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)

                Text("Consistent tracking helps you and your doctor see patterns.")
                    .font(DesignTokens.Typography.secondary)
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
                        .fontWeight(.semibold)
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
                .font(DesignTokens.Typography.secondary)
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
                    .font(DesignTokens.Typography.title)
                    .fontWeight(.bold)
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
                            .font(DesignTokens.Typography.secondary)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.secondary)
                        Text("Your data stays private")
                            .font(DesignTokens.Typography.secondary)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.secondary)
                        Text("Download: ~1.8 GB")
                            .font(DesignTokens.Typography.secondary)
                        Spacer()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xxl)
            }

            Spacer()

            Button(action: {
                // TODO: Trigger ML model download
                withAnimation {
                    currentPage = 4
                }
            }) {
                Text("Download Model")
                    .fontWeight(.semibold)
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

    // MARK: - Page 5: Ready

    private var readyPage: some View {
        VStack(spacing: DesignTokens.Spacing.xxl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: DesignTokens.Dimensions.heroIconSize))
                .foregroundColor(DesignTokens.Colors.highlight)

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("You're All Set!")
                    .font(DesignTokens.Typography.largeTitle)
                    .fontWeight(.bold)

                Text("Start by logging how you're feeling today. Your first entry takes less than a minute.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, DesignTokens.Spacing.xxl)
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                if speechRecognizer.authorizationStatus == .authorized {
                    Label("Voice input enabled", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.secondary)
                }

                // TODO: Check notification permission status
                // For now, just show placeholder
                Label("Reminders configured", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.secondary)
                    .opacity(0.5)

                // TODO: Check ML model download status
                Label("Model download pending", systemImage: "arrow.down.circle")
                    .foregroundColor(.secondary)
            }
            .font(DesignTokens.Typography.secondary)

            Spacer()

            Button(action: {
                completeOnboarding()
            }) {
                Text("Start Journaling")
                    .fontWeight(.semibold)
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
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}

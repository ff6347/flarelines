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
                        .font(.subheadline)
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
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.red)

            VStack(spacing: 16) {
                Text("Welcome to Wolfsbit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Track your chronic illness symptoms with voice-first journaling. Designed for people with fatigue and brain fog.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 16) {
                Label("Voice input for easy logging", systemImage: "mic.fill")
                    .font(.headline)

                Label("Daily health tracking", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)

                Label("Export reports for your doctor", systemImage: "doc.text.fill")
                    .font(.headline)
            }
            .frame(maxWidth: 300)

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
                    .cornerRadius(DesignTokens.CornerRadius.lg)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Page 2: Voice Permissions

    private var voicePermissionsPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                Text("Voice Input Makes Logging Easy")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Answer daily questions using your voice. Wolfsbit needs microphone and speech recognition access.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                Text("Typing can be exhausting when you're fatigued. Voice input is faster and easier.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    requestSpeechPermissions()
                }) {
                    Text("Allow Microphone & Speech")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.highlight)
                        .foregroundColor(.white)
                        .cornerRadius(DesignTokens.CornerRadius.lg)
                }

                Button("I'll enable this later") {
                    withAnimation {
                        currentPage = 2
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Page 3: Notifications

    private var notificationsPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "bell.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            VStack(spacing: 16) {
                Text("Daily Reminders (Optional)")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Get reminded to log your symptoms. You can adjust frequency during flare-ups.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                Text("Consistent tracking helps you and your doctor see patterns.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    requestNotificationPermissions()
                }) {
                    Text("Enable Reminders")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.highlight)
                        .foregroundColor(.white)
                        .cornerRadius(DesignTokens.CornerRadius.lg)
                }

                Button("Skip for now") {
                    withAnimation {
                        currentPage = 3
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Page 4: ML Model

    private var mlModelPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.purple)

            VStack(spacing: 16) {
                Text("Smart Health Scoring (Optional)")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Download an AI model that learns your patterns and provides more accurate health scores over time.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Runs on your device")
                            .font(.subheadline)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Your data stays private")
                            .font(.subheadline)
                        Spacer()
                    }

                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                        Text("Download: ~50-100 MB")
                            .font(.subheadline)
                        Spacer()
                    }
                }
                .padding(.horizontal, 48)

                Text("You can use the app without this. It will use basic scoring until you download the model.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                Button(action: {
                    // TODO: Trigger ML model download (Phase 2+)
                    withAnimation {
                        currentPage = 4
                    }
                }) {
                    Text("Download Now")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.highlight)
                        .foregroundColor(.white)
                        .cornerRadius(DesignTokens.CornerRadius.lg)
                }

                Button("Download Later") {
                    withAnimation {
                        currentPage = 4
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Page 5: Ready

    private var readyPage: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Start by logging how you're feeling today. Your first entry takes less than a minute.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)
            }

            VStack(alignment: .leading, spacing: 12) {
                if speechRecognizer.authorizationStatus == .authorized {
                    Label("Voice input enabled", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }

                // TODO: Check notification permission status
                // For now, just show placeholder
                Label("Reminders configured", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .opacity(0.5)

                // TODO: Check ML model download status (Phase 2+)
                Label("Basic scoring ready", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            .font(.subheadline)

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
                    .cornerRadius(DesignTokens.CornerRadius.lg)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
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

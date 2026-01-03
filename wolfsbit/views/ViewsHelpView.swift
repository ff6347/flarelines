// ABOUTME: Help and support view with onboarding replay and usage guidance.
// ABOUTME: Explains app features including logging, voice input, and data viewing.

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingOnboarding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                Text("Help & Support")
                    .font(DesignTokens.Typography.largeTitle)
                    .fontWeight(.bold)

                // Re-run Onboarding button
                Button(action: {
                    showingOnboarding = true
                }) {
                    Label("Re-run Onboarding", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.highlight)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
                }
                .sheet(isPresented: $showingOnboarding) {
                    OnboardingView(isPresented: $showingOnboarding)
                }

                HelpSection(
                    title: "Getting Started",
                    icon: "info.circle",
                    content: "Wolfsbit helps you track your chronic illness journey. Log daily entries by answering questions about your health, and visualize your progress over time."
                )
                
                HelpSection(
                    title: "Logging Entries",
                    icon: "pencil.circle",
                    content: "Use the LOG tab to answer daily health questions. You can type your answers or use voice input for easier entry. Complete all questions and tap Save to record your entry."
                )
                
                HelpSection(
                    title: "Voice Input",
                    icon: "mic.circle",
                    content: "Tap the Voice Input button to speak your answers. The app will transcribe your speech into text, which you can edit before saving."
                )
                
                HelpSection(
                    title: "Viewing Data",
                    icon: "chart.line.uptrend.xyaxis.circle",
                    content: "The DATA tab shows your health progress over time. Use the time range buttons to view different periods. Scroll down to see detailed journal entries grouped by date."
                )
                
                HelpSection(
                    title: "Privacy",
                    icon: "lock.circle",
                    content: "All your data is stored securely on your device. Your health information is private and never shared without your permission."
                )
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("Help")
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

struct HelpSection: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(DesignTokens.Colors.highlight)
                    .font(DesignTokens.Typography.title2)
                Text(title)
                    .font(DesignTokens.Typography.headline)
            }

            Text(content)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)

            Divider()
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

#Preview {
    HelpView()
}

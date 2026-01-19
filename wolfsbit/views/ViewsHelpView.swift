// ABOUTME: Help and support view with onboarding replay and usage guidance.
// ABOUTME: Explains the two-step journal flow, voice input, and data viewing.

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingOnboarding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                Text("help.title")
                    .font(DesignTokens.Typography.title)
                    .fontWeight(DesignTokens.Weight.strong)

                // Re-run Onboarding button
                Button(action: {
                    showingOnboarding = true
                }) {
                    Label("help.rerunOnboarding", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.highlight)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
                }
                .sheet(isPresented: $showingOnboarding) {
                    OnboardingView(isPresented: $showingOnboarding, onComplete: {
                        dismiss()
                    })
                }

                HelpSection(
                    titleKey: "help.gettingStarted.title",
                    icon: "info.circle",
                    contentKey: "help.gettingStarted.content"
                )

                HelpSection(
                    titleKey: "help.journalFlow.title",
                    icon: "pencil.circle",
                    contentKey: "help.journalFlow.content"
                )

                HelpSection(
                    titleKey: "help.voiceInput.title",
                    icon: "mic.circle",
                    contentKey: "help.voiceInput.content"
                )

                HelpSection(
                    titleKey: "help.viewingData.title",
                    icon: "chart.line.uptrend.xyaxis.circle",
                    contentKey: "help.viewingData.content"
                )

                HelpSection(
                    titleKey: "help.mlScoring.title",
                    icon: "brain.head.profile",
                    contentKey: "help.mlScoring.content"
                )

                HelpSection(
                    titleKey: "help.privacy.title",
                    icon: "lock.circle",
                    contentKey: "help.privacy.content"
                )
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle(Text("Help"))
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
    let titleKey: LocalizedStringKey
    let icon: String
    let contentKey: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(DesignTokens.Colors.highlight)
                    .font(DesignTokens.Typography.heading)
                Text(titleKey)
                    .font(DesignTokens.Typography.subheading)
            }

            Text(contentKey)
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

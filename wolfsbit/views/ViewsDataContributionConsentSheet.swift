// ABOUTME: Consent sheet explaining data contribution for research purposes.
// ABOUTME: Shown when user first enables data contribution toggle.

import SwiftUI

struct DataContributionConsentSheet: View {
    @Binding var isPresented: Bool
    let onAgree: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                    // Header
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 48))
                            .foregroundColor(DesignTokens.Colors.highlight)

                        Text("Help Improve Wolfsbit")
                            .font(DesignTokens.Typography.heading)
                            .fontWeight(DesignTokens.Weight.emphasis)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, DesignTokens.Spacing.lg)

                    // Explanation
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                        Text("Help improve this research by sharing anonymized entries. Only journal text and scores are shared - no personal identifiers. This data supports academic research on AI-assisted health tracking.")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)

                        Divider()

                        // What's shared
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("What's shared:")
                                .font(DesignTokens.Typography.subheading)
                                .fontWeight(DesignTokens.Weight.emphasis)

                            bulletPoint("Your journal entry text")
                            bulletPoint("The AI-suggested score")
                            bulletPoint("Your final score (if different)")
                        }

                        // What's NOT shared
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                            Text("What's NOT shared:")
                                .font(DesignTokens.Typography.subheading)
                                .fontWeight(DesignTokens.Weight.emphasis)

                            bulletPoint("Your name or identity", negative: true)
                            bulletPoint("Timestamps or dates", negative: true)
                            bulletPoint("Device information", negative: true)
                            bulletPoint("Any personal identifiers", negative: true)
                        }

                        Divider()

                        // Research context
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("About This Research")
                                .font(DesignTokens.Typography.subheading)
                                .fontWeight(DesignTokens.Weight.emphasis)

                            Text("Wolfsbit is part of a master's thesis exploring AI-assisted health journaling. This is an academic project with no commercial intent. Your contributions help improve the AI model for everyone.")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)

                    Spacer(minLength: DesignTokens.Spacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: DesignTokens.Spacing.md) {
                    Button(action: {
                        onAgree()
                        isPresented = false
                    }) {
                        Text("I Agree")
                            .fontWeight(DesignTokens.Weight.emphasis)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(DesignTokens.Colors.highlight)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg, style: .continuous))
                    }

                    Text("You can disable this anytime in Settings")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)
                }
                .padding(DesignTokens.Spacing.lg)
                .background(.ultraThinMaterial)
            }
        }
    }

    private func bulletPoint(_ text: String, negative: Bool = false) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: negative ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(negative ? .secondary : .green)
                .font(.system(size: 16))
            Text(text)
                .font(DesignTokens.Typography.body)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    DataContributionConsentSheet(isPresented: .constant(true), onAgree: {})
}

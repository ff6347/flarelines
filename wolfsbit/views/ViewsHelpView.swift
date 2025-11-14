//
//  HelpView.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import SwiftUI

struct HelpView: View {
    @State private var showingOnboarding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Help & Support")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Re-run Onboarding button
                Button(action: {
                    showingOnboarding = true
                }) {
                    Label("Re-run Onboarding", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
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
    }
}

struct HelpSection: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(title)
                    .font(.headline)
            }
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    HelpView()
}

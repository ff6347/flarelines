// ABOUTME: Full-screen journal editor with two-step entry flow.
// ABOUTME: Step 1: Text/voice diary entry. Step 2: Activity rating (0-3).

import SwiftUI
import Speech
import CoreData

struct JournalEditorView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var speechRecognizer = SpeechRecognizer()

    // Entry state
    @State private var journalText = ""
    @State private var activityScore: Double = 1
    @State private var currentPage = 0

    // UI state
    @FocusState private var isEditorFocused: Bool
    @State private var showingSavedAlert = false

    // Sheet presentation
    @State private var showingData = false
    @State private var showingHelp = false
    @State private var showingSettings = false

    // Recording pulse animation
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with action button
                HStack {
                    Spacer()
                    headerButton
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Two-page content
                TabView(selection: $currentPage) {
                    textEntryPage
                        .tag(0)

                    activityRatingPage
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                // Page indicator spacing
                Spacer()
                    .frame(height: 24)

                // Toolbar
                editorToolbar
                    .padding(.bottom, 8)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Entry Saved", isPresented: $showingSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your journal entry has been saved.")
        }
        .sheet(isPresented: $showingData) {
            NavigationView {
                DataView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $showingHelp) {
            NavigationView {
                HelpView()
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationView {
                SettingsView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onChange(of: currentPage) { _, newPage in
            // Stop recording when leaving page 1
            if newPage != 0 && speechRecognizer.isRecording {
                stopRecordingAndAppendText()
            }
        }
    }

    // MARK: - Header Button

    @ViewBuilder
    private var headerButton: some View {
        if currentPage == 0 {
            // Page 1: Navigate to page 2
            Button(action: { withAnimation { currentPage = 1 } }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(DesignTokens.Colors.highlight)
                    .clipShape(Circle())
            }
        } else {
            // Page 2: Save entry
            Button(action: saveEntry) {
                Image(systemName: "checkmark")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(DesignTokens.Colors.highlight)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Text Entry Page

    private var textEntryPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("How are you doing today?")
                .font(.title3)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top, DesignTokens.Spacing.xl)

            Divider()
                .background(Color.gray.opacity(0.5))
                .padding(.horizontal)
                .padding(.top, DesignTokens.Spacing.sm)

            // Text editor area
            ZStack(alignment: .topLeading) {
                if speechRecognizer.isRecording {
                    // Live transcription view
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            if !journalText.isEmpty {
                                Text(journalText)
                                    .foregroundColor(.white)
                            }
                            if !speechRecognizer.transcript.isEmpty {
                                Text(speechRecognizer.transcript)
                                    .foregroundColor(.gray)
                            }
                        }
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                    }
                } else {
                    TextEditor(text: $journalText)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .font(.body)
                        .foregroundColor(.white)
                        .focused($isEditorFocused)
                        .padding(.horizontal, DesignTokens.Spacing.md)
                        .padding(.top, DesignTokens.Spacing.sm)
                }

                // Placeholder
                if journalText.isEmpty && !speechRecognizer.isRecording {
                    Text("Start writing...")
                        .font(.body)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 17)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }
            }

            Spacer()
        }
    }

    // MARK: - Activity Rating Page

    private var activityRatingPage: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Rate your activity!")
                .font(.title3)
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.top, DesignTokens.Spacing.xl)

            // Slider with tick marks
            VStack(spacing: DesignTokens.Spacing.sm) {
                Slider(value: $activityScore, in: 0...3, step: 1)
                    .tint(DesignTokens.Colors.highlight)
                    .padding(.horizontal)
                    .padding(.top, DesignTokens.Spacing.lg)

                // Tick mark labels
                HStack {
                    Text("0")
                    Spacer()
                    Text("1")
                    Spacer()
                    Text("2")
                    Spacer()
                    Text("3")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 20)
            }

            Spacer()
        }
    }

    // MARK: - Editor Toolbar

    private var editorToolbar: some View {
        HStack(spacing: 0) {
            // Mic button with pulse animation when recording
            Button(action: toggleVoiceInput) {
                Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                    .foregroundColor(speechRecognizer.isRecording ? DesignTokens.Colors.highlight : .white)
                    .scaleEffect(isPulsing ? 1.2 : 1.0)
                    .animation(
                        speechRecognizer.isRecording
                            ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                            : .default,
                        value: isPulsing
                    )
            }
            .frame(maxWidth: .infinity)
            .onChange(of: speechRecognizer.isRecording) { _, isRecording in
                isPulsing = isRecording
            }

            // Data button
            Button(action: { showingData = true }) {
                Image(systemName: "cylinder.split.1x2")
            }
            .frame(maxWidth: .infinity)

            // Help button
            Button(action: { showingHelp = true }) {
                Image(systemName: "questionmark.circle")
            }
            .frame(maxWidth: .infinity)

            // Settings button
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape")
            }
            .frame(maxWidth: .infinity)

            // Keyboard toggle button
            Button(action: toggleKeyboard) {
                Image(systemName: isEditorFocused ? "keyboard.chevron.compact.down" : "keyboard")
            }
            .frame(maxWidth: .infinity)
        }
        .font(.title2)
        .foregroundColor(.white)
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(Color(white: 0.15))
        .cornerRadius(DesignTokens.CornerRadius.lg)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func toggleKeyboard() {
        if isEditorFocused {
            isEditorFocused = false
        } else {
            // Only makes sense on page 1 with text editor
            if currentPage == 0 {
                isEditorFocused = true
            }
        }
    }

    private func toggleVoiceInput() {
        if speechRecognizer.isRecording {
            stopRecordingAndAppendText()
        } else {
            // Dismiss keyboard when starting voice
            isEditorFocused = false
            do {
                try speechRecognizer.startRecording()
            } catch {
                print("Failed to start recording: \(error)")
            }
        }
    }

    private func stopRecordingAndAppendText() {
        guard speechRecognizer.isRecording else { return }
        speechRecognizer.stopRecording()
        if !speechRecognizer.transcript.isEmpty {
            journalText += (journalText.isEmpty ? "" : " ") + speechRecognizer.transcript
        }
    }

    private func saveEntry() {
        guard !journalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let entry = JournalEntry(context: viewContext)
        entry.id = UUID()
        entry.timestamp = Date()
        entry.feeling = journalText

        // Store activity score (0-3) in painLevel for now
        // CoreData migration will add proper userScore field
        entry.painLevel = Int16(activityScore)

        // Initialize scoring fields
        entry.heuristicScore = activityScore
        entry.mlScore = 0.0
        entry.scoreConfidence = 0.0
        entry.activeScore = activityScore
        entry.needsReview = false
        entry.isFlaggedDay = false

        do {
            try viewContext.save()
            resetForm()
            showingSavedAlert = true
        } catch {
            print("Error saving entry: \(error)")
        }
    }

    private func resetForm() {
        journalText = ""
        activityScore = 1
        currentPage = 0
        isEditorFocused = false
    }
}

// Keep LogView as alias for compatibility
typealias LogView = JournalEditorView

#Preview {
    JournalEditorView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

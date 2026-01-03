// ABOUTME: Modal view for editing saved journal entries.
// ABOUTME: Allows editing input fields and recalculates scores on save.

import SwiftUI
import CoreData

struct EditEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var entry: JournalEntry

    @State private var feeling: String
    @State private var painLevel: Int16
    @State private var symptoms: String
    @State private var notes: String

    init(entry: JournalEntry) {
        self.entry = entry
        _feeling = State(initialValue: entry.feeling ?? "")
        _painLevel = State(initialValue: entry.painLevel)
        _symptoms = State(initialValue: entry.symptoms ?? "")
        _notes = State(initialValue: entry.notes ?? "")
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text(entry.timestamp, style: .date)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Time")
                        Spacer()
                        Text(entry.timestamp, style: .time)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Entry Details")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling today?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextEditor(text: $feeling)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                } header: {
                    Text("Feeling")
                }

                Section {
                    HStack {
                        Text("Pain Level")
                        Spacer()
                        Stepper("\(painLevel)/10", value: $painLevel, in: 0...10)
                            .foregroundColor(.primary)
                    }

                    Text("How intense is your pain on a scale of 0-10?")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Pain")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What symptoms are you experiencing?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextEditor(text: $symptoms)
                            .frame(height: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                } header: {
                    Text("Symptoms")
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional notes (optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                } header: {
                    Text("Notes")
                }

                Section {
                    HStack {
                        Text("Heuristic Score")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f", entry.heuristicScore))
                            .fontWeight(.semibold)
                    }

                    if entry.mlScore > 0 {
                        HStack {
                            Text("ML Score")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: "%.1f (%.0f%% confidence)", entry.mlScore, entry.scoreConfidence * 100))
                                .fontWeight(.semibold)
                        }
                    }

                    HStack {
                        Text("Active Score")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.1f", entry.activeScore))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    if entry.needsReview {
                        Label("Low confidence - needs review", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Scores (Read-Only)")
                } footer: {
                    Text("Scores are automatically recalculated when you save changes.")
                        .font(.caption)
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveChanges() {
        // Update entry fields
        entry.feeling = feeling.isEmpty ? nil : feeling
        entry.painLevel = painLevel
        entry.symptoms = symptoms.isEmpty ? nil : symptoms
        entry.notes = notes.isEmpty ? nil : notes

        // Recalculate heuristic score from pain level
        entry.heuristicScore = 10.0 - Double(painLevel)

        // TODO: Re-run ML scoring when model is available (Phase 2)
        // For now, use heuristic score as active score
        if entry.mlScore == 0 {
            // No ML model data, use heuristic
            entry.activeScore = entry.heuristicScore
            entry.needsReview = false
        } else {
            // Keep existing ML score but may need re-evaluation
            // This will be handled when ML model is integrated
            entry.activeScore = entry.scoreConfidence >= 0.6 ? entry.mlScore : entry.heuristicScore
        }

        // Save to Core Data
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving entry: \(error)")
            // TODO: Show error alert to user
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let entry = JournalEntry(context: context)
    entry.id = UUID()
    entry.timestamp = Date()
    entry.feeling = "Tired and achy"
    entry.painLevel = 6
    entry.symptoms = "Joint pain, headache"
    entry.heuristicScore = 4.0
    entry.mlScore = 0
    entry.activeScore = 4.0
    entry.notes = "Flare-up today"

    return EditEntryView(entry: entry)
        .environment(\.managedObjectContext, context)
}

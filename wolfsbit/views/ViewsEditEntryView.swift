// ABOUTME: Modal view for editing saved journal entries.
// ABOUTME: Allows editing input fields and recalculates scores on save.

import SwiftUI
import CoreData

struct EditEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var entry: JournalEntry

    @State private var journalText: String
    @State private var activityScore: Double
    @State private var notes: String

    init(entry: JournalEntry) {
        self.entry = entry
        _journalText = State(initialValue: entry.feeling ?? "")
        _activityScore = State(initialValue: Double(entry.painLevel))
        _notes = State(initialValue: entry.notes ?? "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    // Entry Details
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Entry Details")
                            .font(DesignTokens.Typography.headline)
                            .fontWeight(.bold)

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
                    }

                    Divider()

                    // Journal Entry
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Journal Entry")
                            .font(DesignTokens.Typography.headline)
                            .fontWeight(.bold)

                        TextEditor(text: $journalText)
                            .frame(height: DesignTokens.Dimensions.textEditorHeightSmall)
                            .scrollContentBackground(.hidden)
                    }

                    Divider()

                    // Activity Score
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Activity Score")
                            .font(DesignTokens.Typography.headline)
                            .fontWeight(.bold)

                        Slider(value: $activityScore, in: 0...3, step: 1)
                            .tint(DesignTokens.Colors.highlight)

                        HStack {
                            Text("0")
                            Spacer()
                            Text("1")
                            Spacer()
                            Text("2")
                            Spacer()
                            Text("3")
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.secondary)

                        Text("0 = Remission, 1 = Mild, 2 = Moderate, 3 = Severe")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Notes
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Notes")
                            .font(DesignTokens.Typography.headline)
                            .fontWeight(.bold)

                        TextEditor(text: $notes)
                            .frame(height: DesignTokens.Dimensions.textEditorHeightCompact)
                            .scrollContentBackground(.hidden)

                        Text("Optional additional notes")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(DesignTokens.Spacing.lg)
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
        entry.feeling = journalText.isEmpty ? nil : journalText
        entry.painLevel = Int16(activityScore)
        entry.notes = notes.isEmpty ? nil : notes

        // Use activity score as the heuristic/active score
        entry.heuristicScore = activityScore
        entry.activeScore = activityScore

        // Save to Core Data
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving entry: \(error)")
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let entry = JournalEntry(context: context)
    entry.id = UUID()
    entry.timestamp = Date()
    entry.feeling = "Feeling tired today, had some joint pain in the morning but it got better after taking medication."
    entry.painLevel = 2
    entry.heuristicScore = 2.0
    entry.mlScore = 0
    entry.activeScore = 2.0
    entry.notes = "Started new medication"

    return EditEntryView(entry: entry)
        .environment(\.managedObjectContext, context)
}

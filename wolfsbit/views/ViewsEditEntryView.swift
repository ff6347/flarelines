// ABOUTME: Modal view for editing saved journal entries.
// ABOUTME: Allows editing journal text and user score.

import SwiftUI
import CoreData

struct EditEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var entry: JournalEntry

    @State private var journalText: String
    @State private var userScore: Double

    init(entry: JournalEntry) {
        self.entry = entry
        _journalText = State(initialValue: entry.journalText ?? "")
        _userScore = State(initialValue: Double(entry.userScore))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    // Entry Details
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Entry Details")
                            .font(DesignTokens.Typography.subheading)
                            .fontWeight(DesignTokens.Weight.strong)

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

                        if entry.mlScore >= 0 {
                            HStack {
                                Text("ML Score")
                                Spacer()
                                Text("\(entry.mlScore)")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    // Journal Entry
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Journal Entry")
                            .font(DesignTokens.Typography.subheading)
                            .fontWeight(DesignTokens.Weight.strong)

                        TextEditor(text: $journalText)
                            .frame(height: DesignTokens.Dimensions.textEditorHeightSmall)
                            .scrollContentBackground(.hidden)
                    }

                    Divider()

                    // User Score
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("Your Score")
                            .font(DesignTokens.Typography.subheading)
                            .fontWeight(DesignTokens.Weight.strong)

                        Slider(value: $userScore, in: 0...3, step: 1)
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
                    .fontWeight(DesignTokens.Weight.emphasis)
                }
            }
        }
    }

    private func saveChanges() {
        entry.journalText = journalText.isEmpty ? nil : journalText
        entry.userScore = Int16(userScore)

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
    entry.journalText = "Heute bin ich müde aufgewacht, hatte leichte Gelenkschmerzen am Morgen, die aber nach dem Aufstehen besser wurden."
    entry.userScore = 1
    entry.mlScore = 1

    return EditEntryView(entry: entry)
        .environment(\.managedObjectContext, context)
}

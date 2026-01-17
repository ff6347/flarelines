// ABOUTME: Generates sample journal entries for testing and development.
// ABOUTME: Creates realistic patterns with occasional flares and score variations.

import Foundation
import CoreData

struct SampleDataGenerator {

    static func generateSampleEntries(context: NSManagedObjectContext, count: Int = 30) {
        let calendar = Calendar.current

        let journalTexts: [Int16: [String]] = [
            0: [
                "Heute geht es mir richtig gut! Keine Symptome, voller Energie.",
                "Guter Tag, keine Beschwerden. Konnte Sport machen.",
                "Fühle mich super, keine Müdigkeit oder Schmerzen.",
                "Alles bestens heute. Produktiver Tag ohne Einschränkungen."
            ],
            1: [
                "Leichte Müdigkeit am Nachmittag, aber sonst okay.",
                "Kopfschmerzen beim Aufwachen, sind aber weggegangen.",
                "Etwas erschöpft nach der Arbeit. Sonst keine Probleme.",
                "Kleine Gelenkschmerzen am Morgen, wurden im Laufe des Tages besser."
            ],
            2: [
                "Starke Müdigkeit, musste mich ausruhen. Gelenkschmerzen.",
                "Konnte nicht viel machen heute. Habe Ibuprofen genommen.",
                "Schmerzen in mehreren Gelenken. Arzttermin gemacht.",
                "Musste früher Feierabend machen wegen Erschöpfung."
            ],
            3: [
                "Schub - musste im Bett bleiben. Fieber und extreme Erschöpfung.",
                "Sehr schlechter Tag. Konnte kaum aufstehen.",
                "Notfall-Termin beim Arzt wegen akuter Beschwerden.",
                "Alles tut weh. Brauche Ruhe und Medikamente."
            ]
        ]

        var baselineScore: Int16 = 1
        var daysSinceLastFlare = 0
        let flareChance = 0.12
        var inFlare = false
        var flareDuration = 0

        for i in 0..<count {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            entry.timestamp = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()

            // Determine if starting a flare
            if !inFlare && daysSinceLastFlare > 7 && Double.random(in: 0...1) < flareChance {
                inFlare = true
                flareDuration = Int.random(in: 2...4)
                daysSinceLastFlare = 0
            }

            // Calculate score
            let score: Int16
            if inFlare {
                score = Int16.random(in: 2...3)
                flareDuration -= 1
                if flareDuration <= 0 {
                    inFlare = false
                }
            } else {
                let change = Int16.random(in: -1...1)
                baselineScore = max(0, min(1, baselineScore + change))
                score = baselineScore
                daysSinceLastFlare += 1
            }

            entry.userScore = score
            entry.journalText = journalTexts[score]?.randomElement()

            // Simulate some entries already scored by ML, some pending
            if i % 4 == 0 {
                entry.mlScore = -1  // Not scored yet
            } else {
                // ML mostly agrees, occasionally differs by 1
                let mlDiff = Int16.random(in: -1...1)
                entry.mlScore = max(0, min(3, score + mlDiff))
            }

        }

        do {
            try context.save()
            print("Generated \(count) sample journal entries")
        } catch {
            print("Error generating sample data: \(error)")
        }
    }

    static func clearAllData(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = JournalEntry.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()
            print("Cleared all journal entries")
        } catch {
            print("Error clearing data: \(error)")
        }
    }

    static func generateWeekOfEntries(context: NSManagedObjectContext) {
        generateSampleEntries(context: context, count: 7)
    }

    static func generateMonthOfEntries(context: NSManagedObjectContext) {
        generateSampleEntries(context: context, count: 30)
    }

    static func generateYearOfEntries(context: NSManagedObjectContext) {
        generateSampleEntries(context: context, count: 365)
    }
}

// MARK: - Debug View for Testing

#if DEBUG
import SwiftUI

struct DebugControlsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        List {
            Section("Generate Sample Data") {
                Button("Generate 7 Days") {
                    SampleDataGenerator.generateWeekOfEntries(context: viewContext)
                }

                Button("Generate 30 Days") {
                    SampleDataGenerator.generateMonthOfEntries(context: viewContext)
                }

                Button("Generate 1 Year") {
                    SampleDataGenerator.generateYearOfEntries(context: viewContext)
                }
            }

            Section("Danger Zone") {
                Button("Clear All Data", role: .destructive) {
                    SampleDataGenerator.clearAllData(context: viewContext)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Debug Controls")
    }
}

#Preview {
    NavigationView {
        DebugControlsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
#endif

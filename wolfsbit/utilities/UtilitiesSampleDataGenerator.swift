//
//  SampleDataGenerator.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import Foundation
import CoreData

/// Helper to generate sample data for testing and development
struct SampleDataGenerator {
    
    static func generateSampleEntries(context: NSManagedObjectContext, count: Int = 30) {
        let calendar = Calendar.current
        
        let feelings = [
            "Feeling great today, lots of energy",
            "A bit tired but manageable",
            "Not my best day, feeling sluggish",
            "Moderate energy, doing okay",
            "Really struggling today",
            "Much better, energy is up",
            "Rough night, tired",
            "Excellent, very optimistic",
            "Fair, could be better",
            "Exhausted but pushing through"
        ]
        
        let symptoms = [
            "No major symptoms today",
            "Headache in the morning",
            "Some joint pain",
            "Low appetite, fatigue",
            "Feeling nauseous",
            "Back pain, 5/10",
            "Mild dizziness",
            "No symptoms, feeling well",
            "Stomach discomfort",
            "Muscle aches"
        ]
        
        // Generate smooth baseline with occasional flares
        var baselinePainLevel = Double.random(in: 3...5) // Start at a moderate level
        var daysSinceLastFlare = 0
        let flareChance = 0.15 // 15% chance of starting a flare
        var inFlare = false
        var flareDuration = 0
        
        for i in 0..<count {
            let entry = JournalEntry(context: context)
            entry.id = UUID()
            
            // Create entries going back in time
            entry.timestamp = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            
            // Determine if we're starting a flare
            if !inFlare && daysSinceLastFlare > 5 && Double.random(in: 0...1) < flareChance {
                inFlare = true
                flareDuration = Int.random(in: 2...5) // Flares last 2-5 days
                daysSinceLastFlare = 0
            }
            
            // Calculate pain level with smooth transitions
            let painLevel: Double
            if inFlare {
                // During flare: higher pain with some variation
                painLevel = Double.random(in: 6...9)
                flareDuration -= 1
                if flareDuration <= 0 {
                    inFlare = false
                }
            } else {
                // Normal days: gradual changes around baseline
                let change = Double.random(in: -0.5...0.5)
                baselinePainLevel = max(2, min(5, baselinePainLevel + change))
                painLevel = baselinePainLevel + Double.random(in: -0.3...0.3)
                daysSinceLastFlare += 1
            }
            
            // Random but somewhat realistic data
            entry.painLevel = Int16(max(0, min(10, round(painLevel))))
            
            // Match feeling and symptoms to pain level
            if entry.painLevel <= 3 {
                entry.feeling = feelings[0...3].randomElement()
                entry.symptoms = symptoms[7...9].randomElement()
            } else if entry.painLevel <= 6 {
                entry.feeling = feelings[1...5].randomElement()
                entry.symptoms = symptoms[0...5].randomElement()
            } else {
                entry.feeling = feelings[4...9].randomElement()
                entry.symptoms = symptoms[1...6].randomElement()
            }
            
            entry.healthScore = 10.0 - Double(entry.painLevel)
            
            // Keep health score in valid range
            entry.healthScore = max(0, min(10, entry.healthScore))
        }
        
        do {
            try context.save()
            print("✅ Generated \(count) sample journal entries with realistic patterns")
        } catch {
            print("❌ Error generating sample data: \(error)")
        }
    }
    
    static func clearAllData(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = JournalEntry.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("✅ Cleared all journal entries")
        } catch {
            print("❌ Error clearing data: \(error)")
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

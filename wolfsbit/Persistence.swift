//
//  Persistence.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample journal entries for preview
        let calendar = Calendar.current
        for i in 0..<10 {
            let entry = JournalEntry(context: viewContext)
            entry.id = UUID()
            entry.timestamp = calendar.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            entry.feeling = ["Feeling good", "A bit tired", "Energetic", "Moderate", "Not great"].randomElement()
            entry.painLevel = Int16.random(in: 2...8)
            entry.symptoms = ["Headache", "Fatigue", "No symptoms", "Mild discomfort", "Some pain"].randomElement()

            // Set heuristic score
            entry.heuristicScore = 10.0 - Double(entry.painLevel)

            // Simulate some entries with ML scores
            if i % 3 == 0 {
                entry.mlScore = entry.heuristicScore + Double.random(in: -0.5...0.5)
                entry.scoreConfidence = Double.random(in: 0.7...0.95)
                entry.activeScore = entry.mlScore
                entry.needsReview = false
            } else if i % 3 == 1 {
                // Low confidence entry
                entry.mlScore = entry.heuristicScore + Double.random(in: -1.0...1.0)
                entry.scoreConfidence = Double.random(in: 0.3...0.59)
                entry.activeScore = entry.heuristicScore  // Fall back to heuristic
                entry.needsReview = true
            } else {
                // No ML score yet
                entry.mlScore = 0.0
                entry.scoreConfidence = 0.0
                entry.activeScore = entry.heuristicScore
                entry.needsReview = false
            }

            // Flag some days
            entry.isFlaggedDay = (i % 4 == 0)
            entry.notes = entry.isFlaggedDay ? "Particularly difficult day" : nil
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "wolfsbit")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

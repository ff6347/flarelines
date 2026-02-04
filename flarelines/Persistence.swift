// ABOUTME: CoreData persistence controller with lightweight migration.
// ABOUTME: Crashes on failure to preserve user data for recovery.

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let calendar = Calendar.current
        let sampleEntries: [(text: String, userScore: Int16, mlScore: Int16)] = [
            ("Heute geht es mir gut. Keine besonderen Symptome, nur leichte Müdigkeit am Nachmittag.", 0, 0),
            ("Kopfschmerzen seit dem Aufwachen. Habe Ibuprofen genommen.", 1, 1),
            ("Starke Gelenkschmerzen, konnte kaum aufstehen. Termin beim Arzt gemacht.", 2, 2),
            ("Schub - musste im Bett bleiben. Fieber und extreme Erschöpfung.", 3, 3),
            ("Besser als gestern. Noch müde aber keine Schmerzen mehr.", 1, 1),
            ("Guter Tag! Sport gemacht und mich danach gut gefühlt.", 0, 0),
            ("Leichte Symptome am Morgen, aber im Laufe des Tages besser geworden.", 1, -1),
            ("Hautausschlag bemerkt. Dokumentiere für den nächsten Arztbesuch.", 2, -1),
        ]

        for (index, entry) in sampleEntries.enumerated() {
            let journalEntry = JournalEntry(context: viewContext)
            journalEntry.id = UUID()
            journalEntry.timestamp = calendar.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            journalEntry.journalText = entry.text
            journalEntry.userScore = entry.userScore
            journalEntry.mlScore = entry.mlScore
        }

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "flarelines")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable lightweight migration for schema changes
            let description = container.persistentStoreDescriptions.first
            description?.shouldMigrateStoreAutomatically = true
            description?.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

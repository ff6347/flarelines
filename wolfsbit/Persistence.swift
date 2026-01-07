// ABOUTME: CoreData persistence controller with store management.
// ABOUTME: Handles incompatible schema by wiping store (pre-release, no user data).

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        let calendar = Calendar.current
        let sampleEntries: [(text: String, userScore: Int16, mlScore: Int16, flagged: Bool)] = [
            ("Heute geht es mir gut. Keine besonderen Symptome, nur leichte Müdigkeit am Nachmittag.", 0, 0, false),
            ("Kopfschmerzen seit dem Aufwachen. Habe Ibuprofen genommen.", 1, 1, false),
            ("Starke Gelenkschmerzen, konnte kaum aufstehen. Termin beim Arzt gemacht.", 2, 2, true),
            ("Schub - musste im Bett bleiben. Fieber und extreme Erschöpfung.", 3, 3, true),
            ("Besser als gestern. Noch müde aber keine Schmerzen mehr.", 1, 1, false),
            ("Guter Tag! Sport gemacht und mich danach gut gefühlt.", 0, 0, false),
            ("Leichte Symptome am Morgen, aber im Laufe des Tages besser geworden.", 1, -1, false),
            ("Hautausschlag bemerkt. Dokumentiere für den nächsten Arztbesuch.", 2, -1, true),
        ]

        for (index, entry) in sampleEntries.enumerated() {
            let journalEntry = JournalEntry(context: viewContext)
            journalEntry.id = UUID()
            journalEntry.timestamp = calendar.date(byAdding: .day, value: -index, to: Date()) ?? Date()
            journalEntry.journalText = entry.text
            journalEntry.userScore = entry.userScore
            journalEntry.mlScore = entry.mlScore
            journalEntry.isFlaggedDay = entry.flagged
            journalEntry.notes = entry.flagged ? "Wichtiger Tag" : nil
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
        container = NSPersistentContainer(name: "wolfsbit")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Pre-release: delete incompatible stores before loading
            Self.deleteStoreIfIncompatible()
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func deleteStoreIfIncompatible() {
        let fileManager = FileManager.default
        guard let storeURL = defaultStoreURL() else { return }

        // If store doesn't exist, nothing to do
        guard fileManager.fileExists(atPath: storeURL.path) else { return }

        // Try to check if migration is needed
        let modelURL = Bundle.main.url(forResource: "wolfsbit", withExtension: "momd")
        guard let modelURL = modelURL,
              let model = NSManagedObjectModel(contentsOf: modelURL) else { return }

        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: storeURL
            )

            if !model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) {
                // Schema incompatible - delete store (pre-release, no user data)
                deleteStoreFiles(at: storeURL)
            }
        } catch {
            // Can't read metadata - store might be corrupted, delete it
            deleteStoreFiles(at: storeURL)
        }
    }

    private static func defaultStoreURL() -> URL? {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        return urls.first?.appendingPathComponent("wolfsbit.sqlite")
    }

    private static func deleteStoreFiles(at url: URL) {
        let fileManager = FileManager.default
        let storePath = url.path

        let suffixes = ["", "-shm", "-wal"]
        for suffix in suffixes {
            let filePath = storePath + suffix
            if fileManager.fileExists(atPath: filePath) {
                try? fileManager.removeItem(atPath: filePath)
            }
        }
    }
}

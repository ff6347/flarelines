// ABOUTME: Core Data model for journal entries tracking daily health status.
// ABOUTME: Stores diary text with user reference score and ML-predicted score.

import Foundation
import CoreData

@objc(JournalEntry)
public class JournalEntry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var journalText: String?
    @NSManaged public var userScore: Int16      // User's reference score 0-3
    @NSManaged public var mlScore: Int16        // Model output 0-3, -1 = not scored
    @NSManaged public var isFlaggedDay: Bool
    @NSManaged public var notes: String?
}

extension JournalEntry: Identifiable {}

//
//  JournalEntry.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import Foundation
import CoreData

@objc(JournalEntry)
public class JournalEntry: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date

    // User input
    @NSManaged public var feeling: String?
    @NSManaged public var painLevel: Int16
    @NSManaged public var symptoms: String?

    // Scoring (updated)
    @NSManaged public var heuristicScore: Double     // Was: healthScore
    @NSManaged public var mlScore: Double            // New: ML model output (0 if not available)
    @NSManaged public var scoreConfidence: Double    // New: ML confidence (0 if not available)
    @NSManaged public var activeScore: Double        // New: Currently displayed score
    @NSManaged public var needsReview: Bool          // New: True if confidence too low

    // User flags
    @NSManaged public var isFlaggedDay: Bool         // New: User marked as significant
    @NSManaged public var notes: String?             // New: Optional additional notes

    // Computed property for backward compatibility
    public var healthScore: Double {
        get { activeScore }
        set { activeScore = newValue }
    }
}

extension JournalEntry: Identifiable {

}

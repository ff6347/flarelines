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
    @NSManaged public var feeling: String?
    @NSManaged public var painLevel: Int16
    @NSManaged public var symptoms: String?
    @NSManaged public var healthScore: Double
}

extension JournalEntry: Identifiable {
    
}

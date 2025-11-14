// ABOUTME: Core Data model for tracking doctor visits.
// ABOUTME: Used to mark visit dates for "since last visit" report generation.

import Foundation
import CoreData

@objc(DoctorVisit)
public class DoctorVisit: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var visitDate: Date
    @NSManaged public var wasReportExported: Bool    // True if visit created from export
    @NSManaged public var notes: String?             // Optional visit notes
}

extension DoctorVisit: Identifiable {

    // Convenience method to find most recent visit
    static func fetchMostRecent(context: NSManagedObjectContext) -> DoctorVisit? {
        let request: NSFetchRequest<DoctorVisit> = DoctorVisit.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \DoctorVisit.visitDate, ascending: false)]
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }
}

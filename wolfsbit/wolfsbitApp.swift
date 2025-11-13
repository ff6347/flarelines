//
//  wolfsbitApp.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import SwiftUI
import CoreData

@main
struct wolfsbitApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

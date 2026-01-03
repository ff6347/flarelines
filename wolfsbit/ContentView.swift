// ABOUTME: Root view that presents JournalEditorView as the main interface.
// ABOUTME: Other views (Data, Help, Settings) are accessed via sheets from the editor.

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        JournalEditorView()
            .environment(\.managedObjectContext, viewContext)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

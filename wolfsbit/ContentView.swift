//
//  ContentView.swift
//  wolfsbit
//
//  Created by Fabian Moron Zirfas on 13.11.25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // LOG Tab
            NavigationView {
                LogView(context: viewContext)
                    .navigationTitle("LOG")
                    .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.large)
            }
            .tabItem {
                Label("LOG", systemImage: "pencil.circle.fill")
            }
            .tag(0)
            
            // DATA Tab
            NavigationView {
                DataView()
                    .navigationTitle("DATA")
                    .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.large)
            }
            .tabItem {
                Label("DATA", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(1)
            
            // HELP Tab
            NavigationView {
                HelpView()
                    .navigationTitle("HELP")
                    .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.large)
            }
            .tabItem {
                Label("HELP", systemImage: "questionmark.circle.fill")
            }
            .tag(2)
            
            // Settings Tab
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .environment(\.managedObjectContext, viewContext)
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

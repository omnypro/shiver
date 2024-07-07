//
//  ShiverApp.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/1/24.
//

import SwiftUI
import SwiftData
import os

@main
struct ShiverApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TwitchUser.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
        .windowResizability(.contentSize)
    }
}

/// A global log of events for the app.
let logger = Logger()

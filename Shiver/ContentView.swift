//
//  ContentView.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/1/24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedChannel: Channel?
    
    var body: some View {
        NavigationSplitView {
            SidebarView(channels: sampleChannels, selectedChannel: $selectedChannel)
        } detail: {
            if let selectedChannel = selectedChannel {
                MainView(channel: selectedChannel)
            } else {
                Text("Select a channel to view!")
            }
        }
    }
}

let sampleChannels = [
    Channel(displayName: "Avalonstar", game: "Wuthering Waves", profileImageUrl: ""),
    Channel(displayName: "Spoonee", game: "Persona 3", profileImageUrl: "")
]

struct Preview: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

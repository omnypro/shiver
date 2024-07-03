//
//  SidebarView.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/2/24.
//

import SwiftUI

struct SidebarView: View {
    var channels: [Channel]
    @Binding var selectedChannel: Channel?
    
    var body: some View {
        VStack(alignment: .leading) {
            // Followed Channels List
            List(selection: $selectedChannel) {
                Section(header: Text("Live Channels")) {
                    ForEach(channels) { channel in
                        NavigationLink(value: channel) {
                            HStack {
                                Image(channel.profileImageUrl).resizable().frame(width: 40, height: 40)
                                VStack(alignment: .leading) {
                                    Text(channel.displayName).font(.headline)
                                    Text(channel.game).font(.subheadline)
                                }
                            }
                        }
                        .tag(channel)
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("Followed Channels")
            
            // Profile
            // ...
            
        }
    }
}

struct Channel: Identifiable, Hashable {
    var id = UUID()
    var displayName: String
    var game: String
    var profileImageUrl: String
}

//
//  ContentView.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/1/24.
//

import AuthenticationServices
import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var showingLoginAlert = false
    @State private var loginMessage = ""
    @State private var accessToken: String?
    @State private var refreshToken: String?
    
    var body: some View {
        VStack {
            Button("Login with Twitch") {
                startAuthentication()
            }
            .alert(isPresented: $showingLoginAlert) {
                Alert(title: Text("Login"), message: Text(loginMessage), dismissButton: .default(Text("OK")))
            }
            
            if let accessToken = accessToken, let refreshToken = refreshToken {
                Text("Access Token: \(accessToken)")
                Text("Refresh Token: \(refreshToken)")
            }
        }
        .onAppear {
            accessToken = TwitchManager.shared.retrieveToken(forKey: "accessToken")
            refreshToken = TwitchManager.shared.retrieveToken(forKey: "refreshToken")
        }
    }
    
    func startAuthentication() {
        TwitchManager.shared.startAuthentication { error in
            if let error = error {
                loginMessage = "Authentication error: \(error.localizedDescription)"
            } else {
                accessToken = TwitchManager.shared.retrieveToken(forKey: "accessToken")
                refreshToken = TwitchManager.shared.retrieveToken(forKey: "refreshToken")
                loginMessage = "Authentication successful"
            }
            
            showingLoginAlert = true
        }
    }
}

//struct ContentView: View {
//    @State private var isLoggedIn: Bool = false
//    @State private var selectedChannel: Channel?
//    
//    var body: some View {
//        VStack {
//            // Main View
//            NavigationSplitView {
//                SidebarView(channels: sampleChannels, selectedChannel: $selectedChannel)
//            } detail: {
//                if let selectedChannel = selectedChannel {
//                    MainView(channel: selectedChannel)
//                } else {
//                    Text("Select a channel to view!")
//                }
//            }
//        }
//    }
//}
//
//let sampleChannels = [
//    Channel(displayName: "Avalonstar", game: "Wuthering Waves", profileImageUrl: ""),
//    Channel(displayName: "Spoonee", game: "Persona 3", profileImageUrl: "")
//]
//
//struct Preview: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

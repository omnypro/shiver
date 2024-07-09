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
    @State private var user: TwitchUser?
    @State private var streams: [TwitchStream] = []
    
    @Environment(\.modelContext) private var context: ModelContext
    
    var body: some View {
        VStack {
            if let user = user {
                NavigationSplitView {
                    VStack(alignment: .leading) {
                        List($streams) { (stream: Binding<TwitchStream>) in
                            NavigationLink(destination: MainView(channel: stream.wrappedValue)) {
                                VStack(alignment: .leading) {
                                    Text(stream.userName.wrappedValue)
                                        .font(.headline)
                                    Text(stream.gameName.wrappedValue)
                                        .font(.subheadline)
                                }
                                .fixedSize(horizontal: true, vertical: true)
                            }
                        }

//                        Text("User Info:")
//                            .font(.headline)
//                        Text("ID: \(user.id)")
//                        Text("Login: \(user.login)")
//                        Text("Email: \(user.email ?? "")")

                        HStack {
                            AsyncImage(url: URL(string: user.profileImageURL!), scale: 2) { image in
                                image.resizable()
                            } placeholder: {
                                Color.black
                            }
                            .frame(width: 36, height: 36)
                            .clipShape(.rect(cornerRadius: 8))
                            
                            Text(user.displayName)
                        }
                        .padding()
                    }
                } detail: {
                    Text("Select a stream to begin!").font(.headline)
                }
            } else {
                Button("Login with Twitch") {
                    startAuthentication()
                }
            }
        }
        .onAppear {
            accessToken = TwitchManager.shared.retrieveToken(forKey: "accessToken")
            refreshToken = TwitchManager.shared.retrieveToken(forKey: "refreshToken")
            user = TwitchManager.shared.retrieveUser(context: context)
            fetchStreams()
        }
    }
    
    func fetchStreams() {
        TwitchManager.shared.refreshStreams(context: context) { result in
            switch result {
            case .success(let fetchedStreams):
                streams = fetchedStreams
            case .failure(let error):
                print("Failed to fetch streams: \(error)")
            }
        }
    }
    
    func startAuthentication() {
        TwitchManager.shared.startAuthentication(context: context) { error in
            if let error = error {
                loginMessage = "Authentication error: \(error.localizedDescription)"
            } else {
                accessToken = TwitchManager.shared.retrieveToken(forKey: "accessToken")
                refreshToken = TwitchManager.shared.retrieveToken(forKey: "refreshToken")
                user = TwitchManager.shared.retrieveUser(context: context)
                loginMessage = "Authentication successful"
            }
            
            showingLoginAlert = true
        }
    }
}

//struct Preview: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

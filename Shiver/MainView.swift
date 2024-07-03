//
//  MainView.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/2/24.
//

import SwiftUI
import WebKit

struct MainView: View {
    var channel: Channel
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Color.black
                WebView(channelName: channel.displayName.lowercased(), isLoading: $isLoading).aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit).frame(minWidth: 400, idealWidth: 640)
            }
//            VStack(alignment: .leading) {
//                Text("TEST").font(.title)
//                Text(channel.game).font(.subheadline)
//            }
//            .padding()
        }
    }
}

struct WebView: NSViewRepresentable {
    var channelName: String
    @Binding var isLoading: Bool
    
    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        
        let url = URL(string: "https://shiver-embed.omnyist.productions/index.html?channel=\(channelName)")!
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        let url = URL(string: "https://shiver-embed.omnyist.productions/index.html?channel=\(channelName)")!
        let request = URLRequest(url: url)
        nsView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool
        
        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }
    }
}

//
//  MainView.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/2/24.
//

import SwiftUI
import WebKit

struct MainView: View {
    var channel: TwitchStream
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                Color.black
                WebView(channelName: channel.userLogin).aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit).frame(minWidth: 400, idealWidth: 640)
            }
//            VStack(alignment: .leading) {
//                Text("TEST").font(.title)
//                Text(channel.game).font(.subheadline)
//            }
//            .padding()
        }
    }
}

struct WebView: OSViewRepresentable {
    var channelName: String
    
    func makeOSView(context: Context) -> WKWebView {
        let webView = WKWebView()
//        webView.navigationDelegate = context.coordinator
        
        let url = URL(string: "https://shiver-embed.omnyist.productions/index.html?channel=\(channelName)")!
        let request = URLRequest(url: url)
        webView.load(request)
        return webView
    }
    
    func updateOSView(_ osView: WKWebView, context: Context) {
        let url = URL(string: "https://shiver-embed.omnyist.productions/index.html?channel=\(channelName)")!
        let request = URLRequest(url: url)
        osView.load(request)
    }
    
//    func makeCoordinator() -> Coordinator {
//        Coordinator()
//    }
    
    
//    init(channelName: String) {
//        let config = WKWebViewConfiguration()
//        config.preferences.isElementFullscreenEnabled = true
//        config.preferences.isTextInteractionEnabled = false
//
//        self.channelName = channelName
//    }
}

//extension WebView {
//    @MainActor class Coordinator: NSObject, WKNavigationDelegate {
//        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
//            if let url = navigationAction.request.url {
//                return .cancel
//            } else {
//                return .allow
//            }
//        }
//    }
//}

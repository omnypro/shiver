//
//  AuthenticationManager.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/6/24.
//

import AuthenticationServices
import Foundation
import SwiftUI

class AuthenticationManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthenticationManager()
    
    private override init() {}
    
    func startAuthentication(completion: @escaping (String?, String?, Error?) -> Void) {
        let authURL = URL(string: "https://getshiver.app/api/auth/authenticate")!
        let callbackURLScheme = "shiver"
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackURLScheme) { callbackURL, error in
            if let error = error {
                completion(nil, nil, error)
            } else if let callbackURL = callbackURL {
                // Extract access and refresh tokens from the callback URL.
                if let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                   let queryItems = urlComponents.queryItems,
                   let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value,
                   let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value {
                    completion(accessToken, refreshToken, nil)
                } else {
                    completion(nil, nil, nil)
                }
            }
        }
        
        session.presentationContextProvider = self
        session.start()
    }
    
    #if os(macOS)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared()?.windows.last(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
    #endif
    
    #if os(visionOS)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            return windowScene.windows.last(where: \.isKeyWindow) ?? ASPresentationAnchor()
        }
        
        return ASPresentationAnchor()
    }
    #endif
}

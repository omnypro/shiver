//
//  AuthenticationManager.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/6/24.
//

import AuthenticationServices
import Foundation
import SwiftUI
import Security

class TwitchManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = TwitchManager()
    
    private override init() {}
    
    func startAuthentication(completion: @escaping (Error?) -> Void) {
        let authURL = URL(string: "https://getshiver.app/api/auth/authenticate")!
        let callbackURLScheme = "shiver"
        let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackURLScheme) { callbackURL, error in
            if let error = error {
                completion(error)
            } else if let callbackURL = callbackURL {
                // Extract access and refresh tokens from the callback URL.
                if let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                   let queryItems = urlComponents.queryItems,
                   let accessToken = queryItems.first(where: { $0.name == "access_token" })?.value,
                   let refreshToken = queryItems.first(where: { $0.name == "refresh_token" })?.value {
                    self.storeToken(accessToken, forKey: "accessToken")
                    self.storeToken(refreshToken, forKey: "refreshToken")
                    completion(nil)
                } else {
                    completion(nil)
                }
            }
        }
        
        session.presentationContextProvider = self
        session.start()
    }
    
    #if os(macOS)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return NSApplication.shared.windows.last(where: \.isKeyWindow) ?? ASPresentationAnchor()
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
    
    private func storeToken(_ token: String, forKey key: String) {
        let data = Data(token.utf8)
        
        // Delete any existing items.
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as CFDictionary
        SecItemDelete(query)
        
        // Add the new item to the keychain.
        let addQuery = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: data
        ] as CFDictionary
        SecItemAdd(addQuery, nil)
    }
    
    func retrieveToken(forKey key: String) -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query, &dataTypeRef)
        
        if status == errSecSuccess {
            if let data = dataTypeRef as? Data,
               let token = String(data: data, encoding: .utf8) {
                return token
            }
        }
        
        return nil
    }
}

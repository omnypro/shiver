//
//  AuthenticationManager.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/6/24.
//

import Alamofire
import AuthenticationServices
import Foundation
import Security
import SwiftData
import SwiftUI

class TwitchManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = TwitchManager()
    
    private override init() {}
    
    func startAuthentication(context: ModelContext, completion: @escaping (Error?) -> Void) {
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
                    self.fetchUser(accessToken: accessToken, context: context) { error in
                        completion(error)
                    }
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
    
    private func storeUser(_ info: TwitchUser, context: ModelContext) {
        context.insert(info)
        do {
            try context.save()
        } catch {
            print("Failed to save user info: \(error)")
        }
    }
    
    func retrieveUser(context: ModelContext) -> TwitchUser? {
        let request: FetchDescriptor<TwitchUser> = FetchDescriptor()
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Failed to fetch user info: \(error)")
            return nil
        }
    }

    private func fetchUser(accessToken: String, context: ModelContext, completion: @escaping (Error?) -> Void) {
        let url = "https://api.twitch.tv/helix/users"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Client-ID": ProcessInfo.processInfo.environment["TWITCH_CLIENT_ID"]!
        ]
        
        AF.request(url, headers: headers).responseDecodable(of: TwitchUserResponse.self) { response in
            switch response.result {
            case .success(let userResponse):
                guard let user = userResponse.data.first else {
                    completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid data format"]))
                    return
                }
                                
                let payload = TwitchUser(
                    id: user.id,
                    login: user.login,
                    displayName: user.display_name,
                    type: user.type,
                    broadcasterType: user.broadcaster_type,
                    userDescription: user.description,
                    profileImageURL: user.profile_image_url,
                    offlineImageURL: user.offline_image_url,
                    email: user.email
                )
                
                self.storeUser(payload, context: context)
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }
    
    func fetchStreams(accessToken: String, context: ModelContext, completion: @escaping (Result<[TwitchStream], Error>) -> Void) {
        guard let user: TwitchUser = TwitchManager.shared.retrieveUser(context: context) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found"])))
            return
        }
        
        let url = "https://api.twitch.tv/helix/streams/followed?user_id=\(user.id)"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "Client-ID": ProcessInfo.processInfo.environment["TWITCH_CLIENT_ID"]!
        ]
        
        let decoder: JSONDecoder = {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return decoder
        }()
        
        AF.request(url, headers: headers).responseDecodable(of: TwitchStreamResponse.self, decoder: decoder) { response in
            switch response.result {
            case.success(let streamResponse):
                completion(.success(streamResponse.data))
            case.failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func refreshStreams(context: ModelContext, completion: @escaping (Result<[TwitchStream], Error>) -> Void) {
        guard let accessToken = retrieveToken(forKey: "accessToken") else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Access token not found"])))
            return
        }
        
        fetchStreams(accessToken: accessToken, context: context, completion: completion)
    }
}

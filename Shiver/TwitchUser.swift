//
//  TwitchUser.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/7/24.
//

import Foundation
import SwiftData

@Model
final class TwitchUser {
    var id: String
    var login: String
    var displayName: String
    var type: String?
    var broadcasterType: String?
    var userDescription: String?
    var profileImageURL: String?
    var offlineImageURL: String?
    var email: String?

    init(id: String, login: String, displayName: String, type: String? = nil, broadcasterType: String? = nil, userDescription: String? = nil, profileImageURL: String? = nil, offlineImageURL: String? = nil, email: String? = nil) {
        self.id = id
        self.login = login
        self.displayName = displayName
        self.type = type
        self.broadcasterType = broadcasterType
        self.userDescription = userDescription
        self.profileImageURL = profileImageURL
        self.offlineImageURL = offlineImageURL
        self.email = email
    }
}

struct TwitchUserResponse: Decodable {
    let data: [User]
    
    struct User: Decodable {
        let id: String
        let login: String
        let display_name: String
        let type: String?
        let broadcaster_type: String?
        let description: String?
        let profile_image_url: String?
        let offline_image_url: String?
        let email: String?
    }
}

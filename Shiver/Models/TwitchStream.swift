//
//  TwitchStream.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/8/24.
//

import SwiftData

@Model
final class TwitchStream: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case userName
        case userLogin
        case gameId
        case gameName
        case type
        case title
        case viewerCount
        case startedAt
        case language
        case thumbnailURL = "thumbnailUrl"
        case tags
        case isMature
    }
    
    var id: String
    var userId: String
    var userLogin: String
    var userName: String
    var gameId: String
    var gameName: String
    var type: String
    var title: String
    var viewerCount: Int
    var startedAt: String
    var language: String
    var thumbnailURL: String
    var tags: [String]
    var isMature: Bool
    
    init(id: String, userId: String, userLogin: String, userName: String, gameId: String, gameName: String, type: String, title: String, viewerCount: Int, startedAt: String, language: String, thumbnailURL: String, tags: [String], isMature: Bool) {
        self.id = id
        self.userId = userId
        self.userLogin = userLogin
        self.userName = userName
        self.gameId = gameId
        self.gameName = gameName
        self.type = type
        self.title = title
        self.viewerCount = viewerCount
        self.startedAt = startedAt
        self.language = language
        self.thumbnailURL = thumbnailURL
        self.tags = tags
        self.isMature = isMature
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.userName = try container.decode(String.self, forKey: .userName)
        self.userLogin = try container.decode(String.self, forKey: .userLogin)
        self.gameId = try container.decode(String.self, forKey: .gameId)
        self.gameName = try container.decode(String.self, forKey: .gameName)
        self.type = try container.decode(String.self, forKey: .type)
        self.title = try container.decode(String.self, forKey: .title)
        self.viewerCount = try container.decode(Int.self, forKey: .viewerCount)
        self.startedAt = try container.decode(String.self, forKey: .startedAt)
        self.language = try container.decode(String.self, forKey: .language)
        self.thumbnailURL = try container.decode(String.self, forKey: .thumbnailURL)
        self.tags = try container.decode([String].self, forKey: .tags)
        self.isMature = try container.decode(Bool.self, forKey: .isMature)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(userName, forKey: .userName)
        try container.encode(gameId, forKey: .gameId)
        try container.encode(type, forKey: .type)
        try container.encode(viewerCount, forKey: .viewerCount)
        try container.encode(startedAt, forKey: .startedAt)
        try container.encode(language, forKey: .language)
        try container.encode(thumbnailURL, forKey: .thumbnailURL)
        try container.encode(tags, forKey: .tags)
        try container.encode(isMature, forKey: .isMature)
    }
}

struct TwitchStreamResponse: Decodable {
    let data: [TwitchStream]
}

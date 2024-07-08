//
//  TwitchStream.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/8/24.
//

final class TwitchStream {
    var id: String
    var userId: String
    var userLogin: String
    var userName: String
    var gameId: String
    var gameName: String
    var type: String
    var viewerCount: Int
    var startedAt: String
    var language: String
    var thumbnailURL: String
    var tags: [String]
    var isMature: Bool
    
    init(id: String, userId: String, userLogin: String, userName: String, gameId: String, gameName: String, type: String, viewerCount: Int, startedAt: String, language: String, thumbnailURL: String, tags: [String], isMature: Bool) {
        self.id = id
        self.userId = userId
        self.userLogin = userLogin
        self.userName = userName
        self.gameId = gameId
        self.gameName = gameName
        self.type = type
        self.viewerCount = viewerCount
        self.startedAt = startedAt
        self.language = language
        self.thumbnailURL = thumbnailURL
        self.tags = tags
        self.isMature = isMature
    }

}

struct TwitchStreamResponse: Decodable {
    let data: [Stream]
    
    struct Stream: Decodable {
        let id: String
        let user_id: String
        let user_login: String
        let user_name: String
        let game_id: String
        let game_name: String
        let type: String
        let viewer_count: Int
        let started_at: String
        let language: String
        let thumbnail_url: String
        let tags: [String]
        let is_mature: Bool
    }
}

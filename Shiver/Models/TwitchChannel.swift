//
//  TwitchChannel.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/8/24.
//

import Foundation
import SwiftData

@Model
final class TwitchChannel {
    var broadcasterId: String
    var broadcasterLogin: String
    var broadcasterName: String
    var followedAt: String
    
    init(broadcasterId: String, broadcasterLogin: String, broadcasterName: String, followedAt: String) {
        self.broadcasterId = broadcasterId
        self.broadcasterLogin = broadcasterLogin
        self.broadcasterName = broadcasterName
        self.followedAt = followedAt
    }
}

struct TwitchChannelResponse {
    let data: [Channel]
    
    struct Channel {
        var broadcaster_id: String
        var broadcaster_login: String
        var broadcaster_name: String
        var followed_at: String
    }
}


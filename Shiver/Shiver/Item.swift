//
//  Item.swift
//  Shiver
//
//  Created by Bryan Veloso on 7/1/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

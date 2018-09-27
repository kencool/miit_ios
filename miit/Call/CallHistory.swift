//
//  CallHistory.swift
//  miit
//
//  Created by Ken Sun on 2018/9/26.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation

class CallHistory {
    
    static var latestRoomIDs: [String] = UserDefaults.standard.stringArray(forKey: "latest_rooms") ?? []
    
    static func add(roomId: String) {
        if let i = latestRoomIDs.firstIndex(of: roomId) {
            latestRoomIDs.swap(from: i, to: 0)
        } else {
            latestRoomIDs.insert(roomId, at: 0)
            if latestRoomIDs.count > 10 {
                latestRoomIDs.removeLast()
            }
        }
        UserDefaults.standard.set(latestRoomIDs, forKey: "latest_rooms")
    }
}

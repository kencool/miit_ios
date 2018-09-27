//
//  CoreMediaExt.swift
//  miit
//
//  Created by Ken Sun on 2018/9/13.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation

extension CMVideoDimensions: Hashable {
    
    public var hashValue: Int {
        get {
            return Int(width) &+ Int(height)
        }
    }
}

public func ==(lhs: CMVideoDimensions, rhs: CMVideoDimensions) -> Bool {
    return lhs.width == rhs.width && lhs.height == rhs.height
}

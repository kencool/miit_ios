//
//  DataExt.swift
//  miit
//
//  Created by Ken Sun on 2018/9/19.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation

extension Data {
    
    mutating func append(uint32 x: UInt32) {
        self.append(UInt8((x >> 24) & 0xFF))
        self.append(UInt8((x >> 16) & 0xFF))
        self.append(UInt8((x >> 8) & 0xFF))
        self.append(UInt8(x & 0xFF))
    }
    
    func getUint32(index: Int) -> UInt32? {
        guard index + MemoryLayout<UInt32>.size <= self.count else {
            return nil
        }
        return (UInt32(self[index]) << 24) + (UInt32(self[index + 1]) << 16) + (UInt32(self[index + 2]) << 8) + UInt32(self[index + 3])
    }
}

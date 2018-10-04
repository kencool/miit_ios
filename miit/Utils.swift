//
//  Utils.swift
//  miit
//
//  Created by Ken Sun on 2018/9/10.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation

let Screen = UIScreen.main.bounds

extension CGRect {
    var x: CGFloat { return self.origin.x }
    var y: CGFloat { return self.origin.y }
    var width: CGFloat { return self.size.width }
    var height: CGFloat { return self.size.height }
}

extension UIView {
    var x: CGFloat { return self.frame.origin.x }
    var y: CGFloat { return self.frame.origin.y }
    var width: CGFloat { return self.frame.size.width }
    var height: CGFloat { return self.frame.size.height }
    var central: CGPoint { return CGPoint(x: self.frame.midX, y: self.frame.midY) }
}

var MyName: String {
    get {
        return UserDefaults.standard.string(forKey: "name") ?? UIDevice.current.name
    }
    set {
        UserDefaults.standard.set(newValue, forKey: "name")
    }
}

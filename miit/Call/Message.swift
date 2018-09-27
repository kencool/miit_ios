//
//  Message.swift
//  miit
//
//  Created by Ken Sun on 2018/9/14.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation
import SwiftyJSON

class Message {
    
    var username: String?
    var text: String
    var textColor: UIColor?
    
    init(username: String?, text: String) {
        self.username = username
        self.text = text
    }
    
    var attributedText: NSAttributedString {
        get {
            let string = NSMutableAttributedString()
            if let name = username {
                let nameStr = NSAttributedString(string: name, attributes: [NSAttributedStringKey.foregroundColor: UIColor.white,
                                                                            NSAttributedStringKey.backgroundColor: textColor ?? UIColor.brown,
                                                                            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)])
                string.append(nameStr)
            }
            string.append(NSAttributedString(string: "  "))
            let textStr = NSAttributedString(string: text, attributes: [NSAttributedStringKey.foregroundColor: textColor ?? UIColor.gray,
                                                                        NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)])
            string.append(textStr)
            return string
        }
    }
    
}

extension Message {
    
    var json: JSON {
        get {
            var dict: [String:Any] = ["type": "message", "payload": text]
            if let v = username {
                dict["sender"] = v
            }
            return JSON(dict)
        }
    }
    
    convenience init(json: JSON) {
        self.init(username: json["sender"].string, text: json["payload"].stringValue)
    }
}

let colors = [UIColor.lightGray,
              UIColor.white,
              UIColor.blue,
              UIColor.green,
              UIColor.red,
              UIColor.yellow,
              UIColor.orange,
              UIColor.purple,
              UIColor.cyan,
              UIColor.brown,
              UIColor.magenta]

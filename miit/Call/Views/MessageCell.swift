//
//  MessageCell.swift
//  miit
//
//  Created by Ken Sun on 2018/9/15.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.indentationWidth = 0
        self.textLabel?.numberOfLines = 0
        self.backgroundColor = UIColor.clear
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 1.0
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.masksToBounds = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.textLabel?.frame = self.contentView.bounds
    }
}

//
//  UIViewExt.swift
//  miit
//
//  Created by Ken Sun on 2018/9/11.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation

extension UIView {
    
    func addButton(type: UIButtonType = .system, title: String, size: CGFloat = 20, _ target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: type)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont(name: "Roboto", size: size)
        button.sizeToFit()
        button.addTarget(target, action: action, for: .touchUpInside)
        self.addSubview(button)
        return button
    }
    
    func addButton(type: UIButtonType = .custom, imageName: String, _ target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: type)
        button.tintColor = UIColor.white
        button.setImage(UIImage(named: imageName), for: .normal)
        button.sizeToFit()
        button.addTarget(target, action: action, for: .touchUpInside)
        self.addSubview(button)
        return button
    }
}

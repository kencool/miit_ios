//
//  UIViewControllerExt.swift
//  miit
//
//  Created by Ken Sun on 2018/9/11.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation

extension UIViewController {
    
    func presentAlertNotice(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    
    func presentAlertYesOrNo(title: String, message: String, yes: ((UIAlertAction) -> Void)? = nil, no: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: yes))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: no))
        self.present(alert, animated: true)
    }
}

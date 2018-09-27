//
//  MICall+Keyboard.swift
//  miit
//
//  Created by Ken Sun on 2018/9/20.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

extension MICallViewController {
    
    @objc func keyboardDidShow(notification: NSNotification) {
        toolBar.isHidden = true
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        toolBar.isHidden = false
    }
    
    @objc func keyboardWillChangeFrame(_ notification: NSNotification) {
        if let userInfo = notification.userInfo {
            let keyboardFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
            let duration:TimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
            let animationCurveRawNSN = userInfo[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber
            let animationCurveRaw = animationCurveRawNSN?.uintValue ?? UIViewAnimationOptions.curveEaseInOut.rawValue
            let animationCurve:UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
            
            chatView.snp.updateConstraints { make in
                let c = keyboardFrame != nil && keyboardFrame!.origin.y < UIScreen.main.bounds.size.height ? -keyboardFrame!.size.height : 0
                make.bottom.equalTo(self.view).offset(c)
            }
            UIView.animate(withDuration: duration, delay: 0, options: animationCurve, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
}

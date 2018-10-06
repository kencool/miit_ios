//
//  Alert.swift
//  miit
//
//  Created by Ken Sun on 2018/10/1.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

class Alert: UIAlertController {

    /// The UIWindow that will be at the top of the window hierarchy. The DBAlertController instance is presented on the rootViewController of this window.
    private lazy var alertWindow: UIWindow = {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = AlertBacked()
        window.backgroundColor = UIColor.clear
        window.windowLevel = UIWindowLevelAlert
        return window
    }()
    
    deinit {
        
    }
    
    /**
     Present the DBAlertController on top of the visible UIViewController.
     
     - parameter flag:       Pass true to animate the presentation; otherwise, pass false. The presentation is animated by default.
     - parameter completion: The closure to execute after the presentation finishes.
     */
    public func show(animated flag: Bool = true, completion: (() -> Void)? = nil) {
        if let rootViewController = alertWindow.rootViewController {
            alertWindow.makeKeyAndVisible()
            rootViewController.present(self, animated: flag, completion: completion)
        }
    }
    
}

// In the case of view controller-based status bar style, make sure we use the same style for our view controller
private class AlertBacked: UIViewController {
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIApplication.shared.statusBarStyle
    }
    
    override var prefersStatusBarHidden: Bool {
        return UIApplication.shared.isStatusBarHidden
    }
}

extension Alert {
    
    class func show(title: String, message: String, ok: ((UIAlertAction) -> Void)? = nil) {
        let alert = Alert(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "ok", style: .cancel, handler: ok))
        alert.show()
    }
    
    class func show(title: String, message: String, yes: ((UIAlertAction) -> Void)? = nil, no: ((UIAlertAction) -> Void)? = nil) {
        let alert = Alert(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: yes))
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: no))
        alert.show()
    }
}

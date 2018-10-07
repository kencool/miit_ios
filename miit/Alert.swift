//
//  Alert.swift
//  miit
//
//  Created by Ken Sun on 2018/10/1.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit
import SwiftEntryKit

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
    
    class func topFloat(title: String, message: String) {
        var attributes = EKAttributes.topFloat
        attributes.hapticFeedbackType = .success
        attributes.entryBackground = .gradient(gradient: .init(colors: [MIColor.royalBlue, MIColor.seaGreen], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10))
        attributes.statusBar = .dark
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .easeOut)
        attributes.positionConstraints.maxSize = .init(width: .constant(value: UIScreen.main.bounds.width), height: .intrinsic)
        
        let title = EKProperty.LabelContent(text: title, style: .init(font: UIFont.boldSystemFont(ofSize: 16), color: UIColor.white))
        let description = EKProperty.LabelContent(text: message, style: .init(font: UIFont.systemFont(ofSize: 14), color: UIColor.white))
        
        let simpleMessage = EKSimpleMessage(image: nil, title: title, description: description)
        let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage)
        
        let contentView = EKNotificationMessageView(with: notificationMessage)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
    
    class func topFloatError(title: String, message: String) {
        var attributes = EKAttributes.topFloat
        attributes.hapticFeedbackType = .error
        attributes.entryBackground = .gradient(gradient: .init(colors: [UIColor.white, UIColor.red], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.3), scale: .init(from: 1, to: 0.7, duration: 0.7)))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 10))
        attributes.statusBar = .dark
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .easeOut)
        attributes.positionConstraints.maxSize = .init(width: .constant(value: UIScreen.main.bounds.width), height: .intrinsic)
        
        let title = EKProperty.LabelContent(text: title, style: .init(font: UIFont.boldSystemFont(ofSize: 16), color: UIColor.white))
        let description = EKProperty.LabelContent(text: message, style: .init(font: UIFont.systemFont(ofSize: 14), color: UIColor.white))
        
        let simpleMessage = EKSimpleMessage(image: nil, title: title, description: description)
        let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage)
        
        let contentView = EKNotificationMessageView(with: notificationMessage)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
    
    class func showError(title: String, message: String) {
        var attributes = EKAttributes.centerFloat
        attributes.hapticFeedbackType = .success
        attributes.displayDuration = .infinity
        attributes.entryBackground = .gradient(gradient: .init(colors: [UIColor.white, UIColor.red], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.screenBackground = .color(color: UIColor(white: 50.0/255.0, alpha: 0.3))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 8))
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        attributes.roundCorners = .all(radius: 8)
        attributes.entranceAnimation = .init(translate: .init(duration: 0.7, spring: .init(damping: 0.7, initialVelocity: 0)),
                                             scale: .init(from: 0.7, to: 1, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.2))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)
        attributes.positionConstraints.maxSize = .init(width: .constant(value: UIScreen.main.bounds.width), height: .intrinsic)
        // popup content
        let image = EKPopUpMessage.ThemeImage(image: EKProperty.ImageContent(image: UIImage(named: "error")!, size: CGSize(width: 60, height: 60), contentMode: .scaleAspectFit))
        let title = EKProperty.LabelContent(text: title, style: EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 24), color: UIColor.white, alignment: .center))
        let description = EKProperty.LabelContent(text: message, style: EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 16), color: UIColor.lightText, alignment: .center))
        let button = EKProperty.ButtonContent(label: .init(text: "got_it".localized(), style: .init(font: UIFont.systemFont(ofSize: 16), color: MIColor.gray)), backgroundColor: UIColor.white, highlightedBackgroundColor: MIColor.gray.withAlphaComponent(0.05))
        // message view
        let message = EKPopUpMessage(themeImage: image, title: title, description: description, button: button) {
            SwiftEntryKit.dismiss()
        }
        let view = EKPopUpMessageView(with: message)
        // display
        SwiftEntryKit.display(entry: view, using: attributes)
    }
    
    class func showYesOrNo(title: String, message: String, yes: (() -> Void)? = nil, no: (() -> Void)? = nil) {
        var attributes = EKAttributes.topFloat
        attributes.hapticFeedbackType = .success
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        //attributes.screenBackground = .color(color: .dimmedLightBackground)
        attributes.entryBackground = .gradient(gradient: .init(colors: [MIColor.royalBlue, MIColor.seaGreen], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.entranceAnimation = .init(translate: .init(duration: 0.7, spring: .init(damping: 1, initialVelocity: 0)), scale: .init(from: 0.6, to: 1, duration: 0.7), fade: .init(from: 0.8, to: 1, duration: 0.3))
        attributes.exitAnimation = .init(scale: .init(from: 1, to: 0.7, duration: 0.3), fade: .init(from: 1, to: 0, duration: 0.3))
        attributes.displayDuration = .infinity
        attributes.border = .value(color: .black, width: 0.5)
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.5, radius: 5))
        attributes.statusBar = .dark
        attributes.positionConstraints.maxSize = .init(width: .constant(value: UIScreen.main.bounds.width), height: .intrinsic)
        
        // Generate textual content
        let title = EKProperty.LabelContent(text: title, style: .init(font: UIFont.boldSystemFont(ofSize: 15), color: .white))
        let description = EKProperty.LabelContent(text: message, style: .init(font: UIFont.systemFont(ofSize: 13), color: .white))
        let simpleMessage = EKSimpleMessage(image: nil, title: title, description: description)
        
        // Generate buttons content
        let buttonFont = UIFont.systemFont(ofSize: 16)
        
        // Close button - Just dismiss entry when the button is tapped
        let closeButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: MIColor.gray)
        let closeButtonLabel = EKProperty.LabelContent(text: "NO", style: closeButtonLabelStyle)
        let closeButton = EKProperty.ButtonContent(label: closeButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  MIColor.gray.withAlphaComponent(0.05)) {
            SwiftEntryKit.dismiss()
            no?()
        }
        
        // Ok Button - Make transition to a new entry when the button is tapped
        let okButtonLabelStyle = EKProperty.LabelStyle(font: buttonFont, color: MIColor.gray)
        let okButtonLabel = EKProperty.LabelContent(text: "YES", style: okButtonLabelStyle)
        let okButton = EKProperty.ButtonContent(label: okButtonLabel, backgroundColor: .clear, highlightedBackgroundColor:  MIColor.gray.withAlphaComponent(0.05)) {
            SwiftEntryKit.dismiss()
            yes?()
        }
        let buttonsBarContent = EKProperty.ButtonBarContent(with: closeButton, okButton, separatorColor: UIColor.lightGray, expandAnimatedly: true)
        
        // Generate the content
        let alertMessage = EKAlertMessage(simpleMessage: simpleMessage, imagePosition: .left, buttonBarContent: buttonsBarContent)
        
        let contentView = EKAlertMessageView(with: alertMessage)
        
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }
}

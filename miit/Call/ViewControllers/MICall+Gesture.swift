//
//  MICall+Gesture.swift
//  miit
//
//  Created by Ken Sun on 2018/9/23.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation
import SwifterSwift

extension MICallViewController {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === panGesture {
            // horizontal panning for toggling full screen
            let v = (gestureRecognizer as! UIPanGestureRecognizer).velocity(in: gestureRecognizer.view)
            return v.y.abs < v.x.abs
        }
        return true
    }
    
    @objc func handlePan(_ gr: UIPanGestureRecognizer) {
        let point = gr.translation(in: gr.view)
        let offset = point.x - panStart.x
        let offsetPercent = min(offset.abs / gr.view!.width * 2, 1)
        switch gr.state {
        case .began:
            panStart = point
            // dismiss keyboard while panning
            chatView.inputTextView.resignFirstResponder()
        case .changed:
            if offset > 0 {
                // pan right, enter full screen
                if !isFullScreen {
                    setFullscreenTransition(alpha: 1 - offsetPercent)
                }
            } else {
                // pan left, leave full screen
                if isFullScreen {
                    setFullscreenTransition(alpha: offsetPercent)
                }
            }
        case .ended, .cancelled:
            isFullScreen = offset > 0
        default:
            break
        }
    }
    
    func setFullscreenTransition(alpha: CGFloat) {
        chatView.alpha = alpha
        toolBar.alpha = alpha
        closeButton.alpha = alpha
        infoButton.alpha = alpha
        if isShowingInfo {
            infoView.alpha = alpha
        }
    }
    
    @objc func handleTap() {
        chatView.inputTextView.resignFirstResponder()
    }
}

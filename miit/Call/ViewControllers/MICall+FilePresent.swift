//
//  MICall+FilePresent.swift
//  miit
//
//  Created by Ken Sun on 2018/9/23.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

extension MICallViewController {
    
    func presentImage(_ image: UIImage, meta: FileMeta) {
        presentFileView(ImagePresentView(image: image, meta: meta))
    }
    
    func presentVideo(_ url: URL, meta: FileMeta) {
        let v = VideoPresentView(url: url, meta: meta)
        presentFileView(v)
        v.videoView.play()
    }
    
    func presentPDF(_ data: Data, meta: FileMeta) {
        guard let v = PDFPresentView(data: data, meta: meta) else {
            Alert.show(title: "open_file_failed".localized(), message: "open_file_failed_message".localized())
            return
        }
        presentFileView(v)
    }
    
    func presentUnknownFile(_ data: Data, meta: FileMeta) {
        presentFileView(CloudPresentView(data: data, meta: meta))
    }
    
    func presentFileView(_ view: FilePresentView) {
        filePresentView?.removeFromSuperview()
        filePresentView = view
        filePresentView?.frame = self.view.bounds
        self.view.addSubview(view)
        
        // file presentation will override gestures to shrink
        panGesture.isEnabled = false
        tapGesture.isEnabled = false
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panFilePresent(_:)))
        pan.delegate = self
        filePresentView?.addGestureRecognizer(pan)
        
        // calculate shrink frame and scale
        let displaySize = view.displaySize
        let isVertical = displaySize.width < displaySize.height
        let width = isVertical ? displaySize.width * 120 / displaySize.height : 120
        let height = isVertical ? 120 : displaySize.height * 120 / displaySize.width
        filePresentShrinkFrame = CGRect(x: callView.localVideoView.x - 8 - width, y: callView.localVideoView.center.y - height / 2, width: width, height: height)
        filePresentShrinkMinimumScale = isVertical ? height / filePresentView!.height : width / filePresentView!.width
    }
    
    @objc func panFilePresent(_ gr: UIPanGestureRecognizer) {
        let point = gr.translation(in: self.view)
        let offset = point.y - panStart.y
        let offsetPercent = min(offset.abs / self.view.height * 2, 1)
        let scale = max(1 - offsetPercent, filePresentShrinkMinimumScale!)
        switch gr.state {
        case .began:
            panStart = point
            // start floating
            filePresentView?.isFloating = true
        case .changed:
            if offset < 0 {
                filePresentView?.frame.size = CGSize(width: self.view.width * scale, height: self.view.height * scale)
                filePresentView?.center.x = self.view.bounds.midX
                filePresentView?.center.y = filePresentShrinkFrame!.midY + (self.view.bounds.midY - filePresentShrinkFrame!.midY) * (1 - offsetPercent)
            }
        case .ended, .cancelled:
            if scale < 0.4 || gr.velocity(in: gr.view).y < -200 {
                // shrink to smallest and resume original pan gesture
                shrinkFilePresent()
                panGesture.isEnabled = true
                tapGesture.isEnabled = true
            } else {
                filePresentView?.frame = self.view.bounds
            }
            // shrink ended, stop floating
            filePresentView?.isFloating = false
        default:
            break
        }
    }
    
    func shrinkFilePresent() {
        filePresentView?.isShrunk = true
        filePresentView?.frame = filePresentShrinkFrame!
        filePresentView?.removeGestureRecognizers()
        
        // tap to resume presentation
        let tap = UITapGestureRecognizer(target: self, action: #selector(enlargeFilePresent))
        filePresentView?.addGestureRecognizer(tap)
        
        // swipe up to dismiss file
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(dismissFilePresent))
        swipe.direction = .up
        filePresentView?.addGestureRecognizer(swipe)
    }
    
    @objc func enlargeFilePresent() {
        filePresentView?.isShrunk = false
        // back to full screen file presentation
        panGesture.isEnabled = false
        tapGesture.isEnabled = false
        filePresentView?.removeGestureRecognizers()
        
        UIView.animate(withDuration: 0.2) { [weak self] in
            if let view = self?.view, let v = self?.filePresentView {
                v.frame = view.bounds
                v.layoutIfNeeded()
            }
        }
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panFilePresent(_:)))
        pan.delegate = self
        filePresentView?.addGestureRecognizer(pan)
    }
    
    @objc func dismissFilePresent() {
        UIView.animate(withDuration: 0.2, animations: { [weak self] in
            if let v = self?.filePresentView {
                v.frame.origin.y = -v.height
                v.alpha = 0.2
            }
        }) { [weak self] finished in
            self?.filePresentView?.removeFromSuperview()
            self?.filePresentView = nil
            self?.filePresentShrinkFrame = nil
            self?.filePresentShrinkMinimumScale = nil
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews.first
    }
}

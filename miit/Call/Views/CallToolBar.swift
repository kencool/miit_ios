//
//  CallToolBar.swift
//  miit
//
//  Created by Ken Sun on 2018/9/17.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

protocol CallToolBarDelegate: class {
    
    func callToolBarDidSelectCloud(_ toolBar: CallToolBar)
    
    func callToolBarDidSelectPhoto(_ toolBar: CallToolBar)
    
    func callToolBar(_ toolBar: CallToolBar, didSwitchVideo on: Bool)
    
    func callToolBar(_ toolBar: CallToolBar, didSwitchAudio on: Bool)
}

class CallToolBar: UIView {

    weak var delegate: CallToolBarDelegate?
    
    private var cloudButton: UIButton!
    
    private var photoButton: UIButton!
    
    private var videoButton: UIButton!
    
    private var audioButton: UIButton!
    
    init() {
        let size = CGSize(width: 50, height: 50)
        let items = 4
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: size.width, height: size.height * CGFloat(items))))
        self.clipsToBounds = true
        let contentInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        cloudButton = self.addButton(imageName: "cloud", self, action: #selector(cloudPressed))
        cloudButton.contentEdgeInsets = contentInsets
        cloudButton.snp.makeConstraints { make in
            make.left.top.right.equalTo(self)
            make.height.equalTo(size.height)
        }
        photoButton = self.addButton(imageName:"photos", self, action: #selector(photoPressed))
        photoButton.contentEdgeInsets = contentInsets
        photoButton.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(cloudButton.snp.bottom)
            make.height.equalTo(size.height)
        }
        videoButton = self.addButton(imageName:"videocam_on", self, action: #selector(videoPressed))
        videoButton.contentEdgeInsets = contentInsets
        videoButton.setImage(UIImage(named: "videocam_off"), for: .selected)
        videoButton.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(photoButton.snp.bottom)
            make.height.equalTo(size.height)
        }
        audioButton = self.addButton(imageName: "mic_on", self, action: #selector(audioPressed))
        audioButton.contentEdgeInsets = contentInsets
        audioButton.setImage(UIImage(named: "mic_off"), for: .selected)
        audioButton.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(videoButton.snp.bottom)
            make.height.equalTo(size.height)
        }
        
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 2.0
        self.layer.shadowOpacity = 1.0
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension CallToolBar {
    
    @objc func cloudPressed() {
        delegate?.callToolBarDidSelectCloud(self)
    }
    
    @objc func photoPressed() {
        delegate?.callToolBarDidSelectPhoto(self)
    }
    
    @objc func videoPressed() {
        videoButton.isSelected = !videoButton.isSelected
        delegate?.callToolBar(self, didSwitchVideo: !videoButton.isSelected)
    }
    
    @objc func audioPressed() {
        audioButton.isSelected = !audioButton.isSelected
        delegate?.callToolBar(self, didSwitchAudio: !audioButton.isSelected)
    }
}

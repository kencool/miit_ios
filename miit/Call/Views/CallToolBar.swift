//
//  CallToolBar.swift
//  miit
//
//  Created by Ken Sun on 2018/9/17.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

protocol CallToolBarDelegate: class {
    
    func callToolBarDidSelectPhoto(_ toolBar: CallToolBar)
    
    func callToolBar(_ toolBar: CallToolBar, didSwitchVideo on: Bool)
    
    func callToolBar(_ toolBar: CallToolBar, didSwitchAudio on: Bool)
}

class CallToolBar: UIView {

    weak var delegate: CallToolBarDelegate?
    
    private var photoButton: UIButton!
    
    private var videoButton: UIButton!
    
    private var audioButton: UIButton!
    
    init() {
        let size = CGSize(width: 50, height: 40)
        super.init(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: size.width, height: size.height * 3)))
        
        photoButton = self.addButton(imageName:"album_photo", self, action: #selector(photoPressed))
        photoButton.snp.makeConstraints { make in
            make.left.top.right.equalTo(self)
            make.height.equalTo(size.height)
        }
        videoButton = self.addButton(imageName:"video_on", self, action: #selector(videoPressed))
        videoButton.setImage(UIImage(named: "video_off"), for: .selected)
        videoButton.snp.makeConstraints { make in
            make.left.right.equalTo(self)
            make.top.equalTo(photoButton.snp.bottom)
            make.height.equalTo(size.height)
        }
        audioButton = self.addButton(imageName: "audio_on", self, action: #selector(audioPressed))
        audioButton.setImage(UIImage(named: "audio_off"), for: .selected)
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

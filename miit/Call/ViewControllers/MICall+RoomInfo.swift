//
//  MICall+RoomInfo.swift
//  miit
//
//  Created by Ken Sun on 2018/9/25.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation

extension MICallViewController {
    
    @objc func toggleRoomInfo() {
        if !isShowingInfo {
            showRoomInfo()
        } else {
            hideRoomInfo()
        }
    }
    
    func showRoomInfo() {
        guard !isShowingInfo else {
            return
        }
        isShowingInfo = true
        infoView.layer.removeAllAnimations()
        infoView.update(roomId: call.roomID, initiator: call.initiatorName, peer: call.peerName)
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.infoView.alpha = 1
        }
    }
    
    @objc func hideRoomInfo() {
        isShowingInfo = false
        UIView.animate(withDuration: 0.2) { [weak self] in
            self?.infoView.alpha = 0
        }
    }
}

class RoomInfoView: UITextView {
    
    private(set) var roomId: String?
    
    private(set) var initiatorName: String?
    
    private(set) var peerName: String?
    
    init() {
        super.init(frame: CGRect.zero, textContainer: nil)
        self.backgroundColor = UIColor.white
        self.layer.borderColor = UIColor.darkGray.cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 10
        self.textContainerInset = UIEdgeInsets(inset: 5)
        self.isEditable = false
        self.isScrollEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(roomId: String?, initiator: String?, peer: String?) {
        self.roomId = roomId
        self.initiatorName = initiator
        self.peerName = peer
        
        let string = NSMutableAttributedString()
        string.append(NSAttributedString(string: "Room ID:\n", attributes: [NSAttributedStringKey.foregroundColor: UIColor.black,
                                                                            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)]))
        string.append(NSAttributedString(string: (roomId ?? "") + "\n", attributes: [NSAttributedStringKey.foregroundColor: MIColor.gray,
                                                                                     NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]))
        string.append(NSAttributedString(string: "Participants:\n", attributes: [NSAttributedStringKey.foregroundColor: UIColor.black,
                                                                                 NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)]))
        var text = (initiator ?? peer ?? "") + "\n"
        var color = initiator != nil ? MIColor.royalBlue : MIColor.seaGreen
        string.append(NSAttributedString(string: text, attributes: [NSAttributedStringKey.foregroundColor: color,
                                                                    NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]))
        text = peer ?? ""
        color = MIColor.seaGreen
        string.append(NSAttributedString(string: text, attributes: [NSAttributedStringKey.foregroundColor: color,
                                                                    NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)]))
        self.attributedText = string
        
        sizeToFit()
    }
}

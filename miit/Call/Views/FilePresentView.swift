//
//  FilePresentView.swift
//  miit
//
//  Created by Ken Sun on 2018/10/1.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

class FilePresentView: UIView {

    let fileMeta: FileMeta
    
    var displaySize: CGSize { return self.size }
    
    var isFloating: Bool = false {
        didSet {
            // no background while floating, which looks clearer
            saveButton?.isHidden = isSaved || isFloating || isShrunk
            self.backgroundColor = UIColor(white: 0, alpha: isFloating ? 0.0 : 0.8)
        }
    }
    
    var isShrunk: Bool = false {
        didSet {
            saveButton?.isHidden = isSaved || isFloating || isShrunk
        }
    }
    
    private(set) var saveButton: UIButton?
    
    var isSaved: Bool = false {
        didSet {
            saveButton?.isHidden = isSaved || isFloating || isShrunk
        }
    }
    
    var canSave: Bool { return true }
    
    init(meta: FileMeta) {
        self.fileMeta = meta
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor(white: 0, alpha: 0.6)
        if canSave {
            saveButton = self.addButton(imageName: "save", self, action: #selector(didPressSaveFile))
            saveButton?.tintColor = UIColor.white
            saveButton?.shadowColor = UIColor.black
            saveButton?.shadowOffset = CGSize(width: 2, height: 2)
            saveButton?.shadowOpacity = 1
            saveButton?.shadowRadius = 2
            saveButton?.snp.makeConstraints { make in
                make.left.equalTo(self).offset(8)
                make.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottomMargin)
                make.width.height.equalTo(50)
            }
        }
        // let subclass setup their views
        setupViews()
        
        if let btn = saveButton {
            bringSubview(toFront: btn)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        // do nothing
    }
    
    @objc private func didPressSaveFile() {
        saveFile()
    }
    
    func panGestureShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func saveFile() {
        // do nothing
    }
    
    func didFinishSaveFile(success: Bool, message: String? = nil) {
        isSaved = success
        if success {
            Alert.topFloat(title: "File Saved".localized(), message: message ?? "file_saved_album".localized())
       }
    }
    
    func saveToCloud(data: Data) {
        Alert.show(title: "save_to_icloud".localized(), message: "save_to_icloud_message".localized(), yes: { [weak self] _ in
            guard let wSelf = self else {
                return
            }
            if Storage.iCloud.save(data: data, filename: getFilename(meta: wSelf.fileMeta)) {
                wSelf.didFinishSaveFile(success: true, message: "file_saved_icloud".localized())
            }
        })
    }
}

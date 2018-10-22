//
//  CloudPresentView.swift
//  miit
//
//  Created by Ken Sun on 2018/10/6.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

class CloudPresentView: FilePresentView {

    let data: Data
    
    var errorLabel: UILabel!
    
    override var displaySize: CGSize {
        return AVMakeRect(aspectRatio: CGSize(width: 3, height: 4), insideRect: UIScreen.main.bounds).size
    }
    
    override var isFloating: Bool {
        didSet {
            errorLabel.isHidden = isFloating || isShrunk
        }
    }
    
    override var isShrunk: Bool {
        didSet {
            errorLabel.isHidden = isShrunk
        }
    }
    
    init(data: Data, meta: FileMeta) {
        self.data = data
        super.init(meta: meta)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupViews() {
        // white view
        let view = UIView()
        view.backgroundColor = UIColor.white
        self.addSubview(view)
        view.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(self.snp.width).multipliedBy(4/3.0)
        }
        // alert
        let iv = UIImageView(image: UIImage(named: "error"))
        view.addSubview(iv)
        iv.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        // message
        errorLabel = UILabel()
        errorLabel.textColor = UIColor.black
        errorLabel.font = UIFont.systemFont(ofSize: 14)
        errorLabel.text = "file_cannot_view".localized()
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        view.addSubview(errorLabel)
        errorLabel.snp.makeConstraints { make in
            make.centerX.equalTo(iv)
            make.top.equalTo(iv.snp.bottom).offset(8)
            
        }
        // change save button image and location
        saveButton?.setImage(UIImage(named: "cloud_upload"), for: .normal)
        saveButton?.tintColor = UIColor.white
        saveButton?.snp.remakeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide).offset(4)
            make.right.equalTo(self.safeAreaLayoutGuide).offset(-8)
        }
    }
    
    override func saveFile() {
        saveToCloud(data: data)
    }
}

//
//  ImagePresentView.swift
//  miit
//
//  Created by Ken Sun on 2018/9/23.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit
import ZoomImageView

class ImagePresentView: FilePresentView {
    
    private var zoomView: ZoomImageView!
    
    private let image: UIImage
    
    var isImageVertical: Bool { return image.size.width < image.size.height }
    
    init(image: UIImage, meta: FileMeta) {
        self.image = image
        super.init(meta: meta)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func setupViews() {
        // zoom image view
        zoomView = ZoomImageView(image: image)
        zoomView.backgroundColor = UIColor.clear
        self.addSubview(zoomView)
        zoomView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    override func saveFile() {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(didSaveImageTo(image:error:context:)), nil)
    }
    
    @objc func didSaveImageTo(image: UIImage?, error: Error?, context: UnsafeMutableRawPointer?) {
        guard error == nil else {
            Alert.show(title: "Save Failed", message: error!.localizedDescription)
            return
        }
        didFinishSaveFile(success: true)
    }
}

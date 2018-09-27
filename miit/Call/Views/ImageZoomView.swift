//
//  ImageZoomView.swift
//  miit
//
//  Created by Ken Sun on 2018/9/23.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

class ImageZoomView: UIView, UIScrollViewDelegate {

    private(set) var scrollView: UIScrollView!
    
    private(set) var imageView: UIImageView!
    
    var isImageVertical: Bool { return imageView.image != nil ? imageView.image!.size.width < imageView.image!.size.height : false }
    
    var imageSize: CGSize? { return imageView.image?.size }
    
    init(image: UIImage?) {
        super.init(frame: CGRect.zero)
        setupViews()
        imageView.image = image
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // scroll view
        scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.maximumZoomScale = 3
        scrollView.minimumZoomScale = 1
        scrollView.zoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        self.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        // image view
        imageView = UIImageView()
        imageView.clipsToBounds = true
        scrollView.addSubview(imageView)
        
        // double tap
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTap)
    }
    
    override func layoutSubviews() {
        guard let image = imageView.image else {
            return
        }
        scrollView.zoomScale = 1
        scrollView.contentOffset = CGPoint.zero
        let frame = AVMakeRect(aspectRatio: image.size, insideRect: self.bounds)
        imageView.frame = frame
    }
}

// MARK: - Scroll View Delegate

extension ImageZoomView {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        scrollView.contentSize = imageView.size
        if imageView.size.height > scrollView.height {
            if imageView.y > 0 {
                imageView.frame.origin.y = 0
            }
        } else {
            imageView.center.y = scrollView.center.y
        }
    }
}

// MARK: - Gesture

extension ImageZoomView {
    
    @objc func doubleTap(_ gr: UITapGestureRecognizer) {
        scrollView.setZoomScale(scrollView.maximumZoomScale, animated: true)
    }
}

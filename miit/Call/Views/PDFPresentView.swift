//
//  PDFPresentView.swift
//  miit
//
//  Created by Ken Sun on 2018/10/3.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit
import PDFKit

class PDFPresentView: FilePresentView {

    override var isFloating: Bool {
        didSet {
            thumbnailView.isHidden = isFloating || isShrunk
        }
    }
    
    override var isShrunk: Bool {
        didSet {
            thumbnailView.isHidden = isShrunk
        }
    }
    
    let rawData: Data
    
    let document: PDFDocument
    
    var pdfView: PDFView!
    
    var thumbnailView: PDFThumbnailView!
    
    var pageNumberLabel: UILabel!
    
    init?(data: Data, meta: FileMeta) {
        guard let doc = PDFDocument(data: data) else {
            return nil
        }
        self.rawData = data
        self.document = doc
        super.init(meta: meta)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupViews() {
        // pdf view
        pdfView = PDFView()
        pdfView.maxScaleFactor = 2
        pdfView.minScaleFactor = 0.01
        //pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: [UIPageViewControllerOptionInterPageSpacingKey: 20])
        pdfView.document = document
        pdfView.backgroundColor = UIColor.clear
        self.addSubview(pdfView)
        pdfView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // thumbnail view
        thumbnailView = PDFThumbnailView()
        thumbnailView.layoutMode = .horizontal
        thumbnailView.pdfView = pdfView
        self.addSubview(thumbnailView)
        thumbnailView.snp.makeConstraints { make in
            make.left.bottom.right.equalToSuperview()
            make.height.equalTo(44)
        }
        
        // page number label
        pageNumberLabel = UILabel()
        pageNumberLabel.backgroundColor = UIColor(white: 0, alpha: 0.7)
        self.addSubview(pageNumberLabel)
        pageNumberLabel.snp.makeConstraints { make in
            make.bottom.equalTo(thumbnailView.snp.top).offset(-14)
            make.centerX.equalToSuperview()
        }
        
        // change save button image and location
        saveButton?.setImage(UIImage(named: "save_icloud"), for: .normal)
        saveButton?.tintColor = UIColor.white
        saveButton?.snp.remakeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide).offset(4)
            make.right.equalTo(self.safeAreaLayoutGuide).offset(-8)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
    }
    
    override func panGestureShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
        if thumbnailView.frame.contains(gr.location(in: gr.view)) {
            return false
        }
        return true
    }
    
    override func saveFile() {
        saveToCloud(data: rawData)
    }
}

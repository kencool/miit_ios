//
//  PDFViewController.swift
//  miit
//
//  Created by Ken Sun on 2018/10/3.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit
import PDFKit

class PDFViewController: UIViewController {

    let document: PDFDocument
    
    var pdfView: PDFView!
    
    var thumbnailView: PDFThumbnailView!
    
    var pageNumberLabel: UILabel!
    
    init(document: PDFDocument) {
        self.document = document
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // pdf view
        pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePage
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true, withViewOptions: [UIPageViewControllerOptionInterPageSpacingKey: 20])
        pdfView.document = document
        pdfView.backgroundColor = UIColor.clear
        self.view.addSubview(pdfView)
        pdfView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        // thumbnail view
        thumbnailView = PDFThumbnailView()
        thumbnailView.layoutMode = .horizontal
        thumbnailView.pdfView = pdfView
        self.view.addSubview(thumbnailView)
        thumbnailView.snp.makeConstraints { make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(44)
        }
        
        // page number label
        pageNumberLabel = UILabel()
        pageNumberLabel.backgroundColor = UIColor(white: 0, alpha: 0.7)
        self.view.addSubview(pageNumberLabel)
        pageNumberLabel.snp.makeConstraints { make in
            make.bottom.equalTo(thumbnailView.snp.top).offset(-14)
            make.centerX.equalToSuperview()
        }
    }
}

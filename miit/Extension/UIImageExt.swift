//
//  UIImageExt.swift
//  miit
//
//  Created by Ken Sun on 2018/9/22.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation

extension UIImage {
    
    static func fixImageOrientation(_ src: UIImage) -> UIImage {
        // No-op if the orientation is already correct
        if src.imageOrientation == .up {
            return src
        }
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform = CGAffineTransform.identity
        switch src.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: src.size.width, y: src.size.height).rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: src.size.width, y: 0).rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: src.size.height).rotated(by: -.pi / 2)
        default:
            break
        }
        switch src.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: src.size.width, y: 0).scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: src.size.height, y: 0).scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        guard let cgImage = src.cgImage else {
            return src
        }
        let ctx = CGContext(data: nil,
                            width: Int(src.size.width),
                            height: Int(src.size.height),
                            bitsPerComponent: cgImage.bitsPerComponent,
                            bytesPerRow: cgImage.bytesPerRow,
                            space: cgImage.colorSpace!,
                            bitmapInfo: cgImage.bitmapInfo.rawValue)
        ctx?.concatenate(transform)
        
        switch src.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx?.draw(cgImage, in: CGRect(x: 0, y: 0, width: src.size.height, height: src.size.width))
        default:
            ctx?.draw(cgImage, in: CGRect(x: 0, y: 0, width: src.size.width, height: src.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context
        guard let fixed = ctx?.makeImage() else {
            return src
        }
        return UIImage(cgImage: fixed)
    }
}

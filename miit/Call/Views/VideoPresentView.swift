//
//  VideoPresentView.swift
//  miit
//
//  Created by Ken Sun on 2018/9/30.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

class VideoPresentView: UIView {

    private(set) var videoView: VideoView
    
    var url: URL { return videoView.url }
    
    init(url: URL) {
        videoView = VideoView(url: url)
        videoView.clipsToBounds = true
        super.init(frame: CGRect.zero)
        self.addSubview(videoView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        videoView.frame = AVMakeRect(aspectRatio: videoView.resolution, insideRect: self.bounds)
    }
}

class VideoView: UIView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    let url: URL
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    
    private(set) var resolution: CGSize!
    
    private var playerItem: AVPlayerItem!
    
    init(url: URL) {
        self.url = url
        super.init(frame: CGRect.zero)
        prepareVideo()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func prepareVideo() {
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return }
        let size = track.naturalSize.applying(track.preferredTransform)
        resolution = CGSize(width: fabs(size.width), height: fabs(size.height))
        
    }
    
    func play() {
        player?.play()
    }
}

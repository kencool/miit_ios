//
//  VideoPresentView.swift
//  miit
//
//  Created by Ken Sun on 2018/9/30.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

class VideoPresentView: FilePresentView {

    let url: URL
    
    private(set) var videoView: VideoView!
    
    init(url: URL) {
        self.url = url
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setupViews() {
        videoView = VideoView(url: url)
        videoView.clipsToBounds = true
        self.addSubview(videoView)
    }
    
    override func layoutSubviews() {
        videoView.frame = AVMakeRect(aspectRatio: videoView.resolution, insideRect: self.bounds)
    }
    
    override func saveFile() {
        guard UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.relativePath) else {
            Alert.show(title: "Save Failed", message: "This video is incompatible to be saved.")
            return
        }
        UISaveVideoAtPathToSavedPhotosAlbum(url.relativePath, self, #selector(didSaveVideoTo(path:error:context:)), nil)
    }
    
    @objc func didSaveVideoTo(path: String?, error: Error?, context: UnsafeMutableRawPointer?) {
        guard error == nil else {
            Alert.show(title: "Save Failed", message: error!.localizedDescription)
            return
        }
        didFinishSaveFile(success: true)
    }
}

class VideoView: UIView {

    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
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
        super.init(frame: CGRect.zero)
        prepareVideo(url: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    func prepareVideo(url: URL) {
        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        guard let track = asset.tracks(withMediaType: AVMediaType.video).first else { return }
        let size = track.naturalSize.applying(track.preferredTransform)
        resolution = CGSize(width: fabs(size.width), height: fabs(size.height))
        assert(resolution != nil, "fetch resolution failed")
        
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { [weak self] _ in
            self?.player?.seek(to: kCMTimeZero)
            self?.player?.play()
        }
    }
    
    func play() {
        player?.play()
    }
}

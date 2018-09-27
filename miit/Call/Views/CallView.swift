//
//  CallView.swift
//  miit
//
//  Created by Ken Sun on 2018/9/12.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

protocol CallViewDelegate: class {
    
    func callView(_ callView: CallView, didStop error: Error?)
}

class CallView: UIView, CallDelegate, RTCEAGLVideoViewDelegate {

    let call: Call
    
    weak var delegate: CallViewDelegate?
    
    fileprivate var remoteVideoView: RTCEAGLVideoView!
    
    fileprivate(set) var localVideoView: RTCCameraPreviewView!
    
    fileprivate var remoteVideoTrack: RTCVideoTrack?

    var videoCapturer: RTCCameraVideoCapturer? { get { return call.client.videoCapturer } }
    
    var captureSession: AVCaptureSession? { get { return call.client.videoCapturer?.captureSession } }
    
    fileprivate var remoteVideoSize = CGSize.zero
    
    init(call: Call) {
        self.call = call
        super.init(frame: CGRect.zero)
        call.delegate = self
        self.backgroundColor = UIColor.black
        
        // remote video view
        remoteVideoView = RTCEAGLVideoView(frame: CGRect.zero)
        remoteVideoView.delegate = self
        self.addSubview(remoteVideoView)

        // local video view
        localVideoView = RTCCameraPreviewView(frame: CGRect.zero)
        self.addSubview(localVideoView)
        localVideoView.snp.makeConstraints { make in
            make.right.equalTo(safeAreaLayoutGuide.snp.rightMargin).offset(-8)
            make.top.equalTo(safeAreaLayoutGuide.snp.topMargin).offset(8)
            make.width.height.equalTo(120)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startCall() {
        call.kickOff()
    }
    
    func stopCall() {
        remoteVideoTrack = nil
        localVideoView.captureSession = nil
        stopCapture()
        call.delegate = nil
        call.hangup(error: nil)
    }
    
    override func layoutSubviews() {
        guard remoteVideoSize.width > 0 && remoteVideoSize.height > 0 else {
            remoteVideoView.frame = self.bounds
            return
        }
        // Aspect fit remote video into bounds.
        remoteVideoView.frame = AVMakeRect(aspectRatio: remoteVideoSize, insideRect: self.bounds)
    }
}

// MARK: - Capture

extension CallView {
    
    func startCapture() {
        let device = selectDevice(for: .front)
        let format = selectFormat(for: device)
        let fps = selectFps(for: format)
        videoCapturer?.startCapture(with: device, format: format, fps: fps)
    }
    
    func stopCapture() {
        videoCapturer?.stopCapture()
    }
    
    func selectDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice {
        let devices = RTCCameraVideoCapturer.captureDevices()
        for device in devices {
            if device.position == position {
                return device
            }
        }
        NSLog("No capture device for position \(position)")
        return devices.first!
    }
    
    func selectFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format {
        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        var selectedFormat: AVCaptureDevice.Format! = nil
        for format in formats {
            let pixelFormat: FourCharCode = CMFormatDescriptionGetMediaSubType(format.formatDescription)
            if pixelFormat == videoCapturer?.preferredOutputPixelFormat() {
                selectedFormat = format
            }
        }
        return selectedFormat ?? formats.first!
    }
    
    func availableVideoResolutions() -> [CMVideoDimensions] {
        var resolutions = Set<CMVideoDimensions>()
        for device in RTCCameraVideoCapturer.captureDevices() {
            for format in RTCCameraVideoCapturer.supportedFormats(for: device) {
                let resolution = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                resolutions.insert(resolution)
            }
        }
        return resolutions.sorted { (lhs, rhs) -> Bool in
            return lhs.width > rhs.width
        }
    }
    
    func selectFps(for format: AVCaptureDevice.Format) -> Int {
        var maxFps: Float64 = 0
        for range in format.videoSupportedFrameRateRanges {
            maxFps = fmax(maxFps, range.maxFrameRate)
        }
        return Int(maxFps)
    }
}

// MARK: - Call Delegate

extension CallView {
    
    func call(_ call: Call, didCreateLocalVideo capturer: RTCCameraVideoCapturer) {
        localVideoView.captureSession = capturer.captureSession
        startCapture()
    }
    
    func call(_ call: Call, didReceiveRemoteVideo track: RTCVideoTrack) {
        if track == remoteVideoTrack {
            return
        }
        // clear
        remoteVideoTrack?.remove(remoteVideoView)
        remoteVideoTrack = nil
        remoteVideoView.renderFrame(nil)
        // assign new
        remoteVideoTrack = track
        remoteVideoTrack?.add(remoteVideoView)
    }
    
    func call(_ call: Call, didDisconnect error: Error?) {
        delegate?.callView(self, didStop: error)
    }
}

// MARK: - RTCEAGLVideoView Delegate

extension CallView {
 
    func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        if videoView === remoteVideoView {
            remoteVideoSize = size
        }
        setNeedsLayout()
    }
}


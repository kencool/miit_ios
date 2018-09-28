//
//  RTCClient.swift
//  miit
//
//  Created by Ken Sun on 2018/9/11.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation
import Async

protocol RTCClientDelegate: class {
    
    func rtcClient(_ client: RTCClient, didCreateLocalVideo capturer: RTCCameraVideoCapturer)
    
    func rtcClient(_ client: RTCClient, didReceiveRemoteVideo track: RTCVideoTrack)
    
    func rtcClient(_ client: RTCClient, didSetLocalOffer sdp: String)
    
    func rtcClientShouldRequestRemoteOffer(_ client: RTCClient)
    
    func rtcClient(_ client: RTCClient, didSetLocalAnswer sdp: String)
    
    func rtcClientDidFinishSdpExchange(_ client: RTCClient)
    
    func rtcClient(_client: RTCClient, didGather iceCandidates: [RTCIceCandidate])
    
    func rtcClient(_ client: RTCClient, didDisconnect error: Error?)
    
    func rtcClient(_ client: RTCClient, didOpen dataChannel: RTCDataChannel, label: RTCClient.DataChannelLabel)
}

class RTCClient: NSObject, RTCPeerConnectionDelegate {
    
    let isInitiator: Bool
    
    weak var delegate: RTCClientDelegate?
    
    private(set) var factory: RTCPeerConnectionFactory!
    private(set) var peerConn: RTCPeerConnection?
    private(set) var videoCapturer: RTCCameraVideoCapturer?
    private(set) var videoTrack: RTCVideoTrack?
    private(set) var audioTrack: RTCAudioTrack?
    private(set) var iceCandidates = [RTCIceCandidate]()
    private(set) var textDataChannel: RTCDataChannel?
    private(set) var fileDataChannel: RTCDataChannel?
    
    let streamId = "miitstream"
    let audioTrackId = "miitstreama0"
    let videoTrackId = "miitstreamv0"
    
    init(isInitiator: Bool) {
        self.isInitiator = isInitiator
        super.init()
    }
    
    func connect() {
        let videoEncoderFactory = RTCVideoEncoderFactoryH264()
        let videoDecoderFactory = RTCVideoDecoderFactoryH264()
        factory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
        
        let iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302", "stun:stun.services.mozilla.com"]),
                          RTCIceServer(urlStrings: ["turn:173.194.203.127:19305?transport=udp",
                                                    "turn:[2607:f8b0:400e:c05::7f]:19305?transport=udp",
                                                    "turn:173.194.203.127:19305?transport=tcp",
                                                    "turn:[2607:f8b0:400e:c05::7f]:19305?transport=tcp"],
                                       username:    "CMrw7dwFEgbAETfdivQYzc/s6OMTIICjBQ",
                                       credential:  "Rdg4lTerPbdb9HDWPvBn7DgHXiA=")]
        let config = RTCConfiguration()
        config.iceServers = iceServers
        config.rtcpMuxPolicy = .require
        config.iceTransportPolicy = .all
        config.iceCandidatePoolSize = 5
        config.sdpSemantics = .unifiedPlan
        //config.continualGatheringPolicy = .gatherContinually
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: ["DtlsSrtpKeyAgreement": "true"])
        
        peerConn = factory.peerConnection(with: config, constraints: constraints, delegate: self)
        
        // data channel
        if isInitiator {
            let textConfig = RTCDataChannelConfiguration()
            textConfig.isOrdered = true
            textDataChannel = peerConn?.dataChannel(forLabel: DataChannelLabel.message.rawValue, configuration: textConfig)
            let fileConfig = RTCDataChannelConfiguration()
            fileConfig.isOrdered = false
            fileConfig.maxRetransmits = 100
            fileConfig.isNegotiated = false
            fileDataChannel = peerConn?.dataChannel(forLabel: DataChannelLabel.file.rawValue, configuration: fileConfig)
        }
        
        // audio
        let audioConstraints = RTCMediaConstraints(mandatoryConstraints: [:], optionalConstraints: nil)
        let audioSource = factory.audioSource(with: audioConstraints)
        audioTrack = factory.audioTrack(with: audioSource, trackId: audioTrackId)
        peerConn!.add(audioTrack!, streamIds: [streamId])
        
        // video
        let videoSource = factory.videoSource()
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource)
        delegate?.rtcClient(self, didCreateLocalVideo: videoCapturer!)
        videoTrack = factory.videoTrack(with: videoSource, trackId: videoTrackId)
        peerConn!.add(videoTrack!, streamIds: [streamId])
        // We can set up rendering for the remote track right away since the transceiver already has an
        // RTCRtpReceiver with a track. The track will automatically get unmuted and produce frames
        // once RTP is received.
        if let track = remoteVideoTrack() {
            delegate?.rtcClient(self, didReceiveRemoteVideo: track)
        }
        
        if isInitiator {
            // send offer
            createOffer()
        } else {
            // wait for offer
            delegate?.rtcClientShouldRequestRemoteOffer(self)
        }
    }
    
    func createOffer() {
        assert(peerConn != nil, "peer connection is nil")
        peerConn?.offer(for: defaultSdpConstraints) { (sdp, error) in
            DispatchQueue.main.async { [weak self] in
                guard let wSelf = self else {
                    return
                }
                if sdp != nil && error == nil {
                    wSelf.setLocalOffer(sdp: sdp!)
                } else {
                    wSelf.disconnect(error)
                    if error == nil {
                        NSLog("Can't create local sdp for offer")
                    }
                }
            }
        }
    }
    
    
    
    func setLocalOffer(sdp: RTCSessionDescription) {
        assert(peerConn != nil, "peer connection is nil")
        peerConn?.setLocalDescription(sdp, completionHandler: { error in
            DispatchQueue.main.async { [weak self] in
                guard let wSelf = self else {
                    return
                }
                if error == nil {
                    wSelf.delegate?.rtcClient(wSelf, didSetLocalOffer: sdp.sdp)
                } else {
                    wSelf.disconnect(error)
                }
            }
        })
    }
    
    func setRemoteAnswer(sdp: RTCSessionDescription) {
        assert(peerConn != nil, "peer connection is nil")
        peerConn?.setRemoteDescription(sdp) { error in
            DispatchQueue.main.async { [weak self] in
                guard let wSelf = self else {
                    return
                }
                if error == nil {
                    wSelf.finishSdpExchange()
                } else {
                    wSelf.disconnect(error)
                }
            }
        }
    }
    
    func setRemoteOffer(sdp: RTCSessionDescription) {
        assert(peerConn != nil, "peer connection is nil")
        peerConn?.setRemoteDescription(sdp) { error in
            DispatchQueue.main.async { [weak self] in
                guard let wSelf = self else {
                    return
                }
                if error == nil {
                    wSelf.createAnswer()
                } else {
                    wSelf.disconnect(error)
                }
            }
        }
    }
    
    func createAnswer() {
        assert(peerConn != nil, "peer connection is nil")
        peerConn?.answer(for: defaultSdpConstraints) { sdp, error in
            DispatchQueue.main.async { [weak self] in
                guard let wSelf = self else {
                    return
                }
                if sdp != nil && error == nil {
                    wSelf.setLocalAnswer(sdp: sdp!)
                } else {
                    wSelf.disconnect(error)
                    if error == nil {
                        NSLog("Can't create local sdp for offer")
                    }
                }
            }
        }
    }
    
    func setLocalAnswer(sdp: RTCSessionDescription) {
        assert(peerConn != nil, "peer connection is nil")
        peerConn?.setLocalDescription(sdp) { error in
            DispatchQueue.main.async { [weak self] in
                guard let wSelf = self else {
                    return
                }
                if error == nil {
                    wSelf.delegate?.rtcClient(wSelf, didSetLocalAnswer: sdp.sdp)
                    wSelf.finishSdpExchange()
                } else {
                    wSelf.disconnect(error)
                }
            }
        }
    }
    
    func finishSdpExchange() {
        delegate?.rtcClientDidFinishSdpExchange(self)
        gatherIceCandidates()
    }
    
    func gatherIceCandidates() {
        if iceCandidates.count > 0 {
            delegate?.rtcClient(_client: self, didGather: iceCandidates)
            return
        }
        Async.main(after: 0.5) { [weak self] in
            self?.gatherIceCandidates()
        }
    }
    
    func addIceCandidates(_ candidates: [RTCIceCandidate]) {
        for candidate in candidates {
            assert(peerConn != nil, "peer connection is nil")
            peerConn?.add(candidate)
        }
    }
    
    func removeIceCandidates(_ candidates: [RTCIceCandidate]) {
        assert(peerConn != nil, "peer connection is nil")
        peerConn?.remove(candidates)
    }
    
    func disconnect(_ error: Error?) {
        factory.stopAecDump()
        peerConn?.stopRtcEventLog()
        peerConn?.close()
        peerConn = nil
        videoCapturer = nil
        videoTrack = nil
        
        delegate?.rtcClient(self, didDisconnect: error)
    }
    
    func remoteVideoTrack() -> RTCVideoTrack? {
        assert(peerConn != nil, "peer connection is nil")
        for transceiver in peerConn!.transceivers {
            if transceiver.mediaType == .video {
                return transceiver.receiver.track as? RTCVideoTrack
            }
        }
        return nil
    }
    
    var defaultSdpConstraints: RTCMediaConstraints {
        let mandatory = [
            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
            kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue,
            kRTCMediaConstraintsVoiceActivityDetection: kRTCMediaConstraintsValueFalse,
        ]
        return RTCMediaConstraints(mandatoryConstraints: mandatory, optionalConstraints: nil)
    }
    
    // MARK: - Peer Connection Delegate
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        NSLog("ice connection state = \(newState.rawValue)")
        if isInitiator && newState == .connected {
            delegate?.rtcClient(self, didOpen: textDataChannel!, label: .message)
            delegate?.rtcClient(self, didOpen: fileDataChannel!, label: .file)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        iceCandidates.append(candidate)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        let hashes = Set(candidates.map { $0.hash })
        iceCandidates = iceCandidates.filter { !hashes.contains($0.hash) }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        guard let label = DataChannelLabel(rawValue: dataChannel.label) else {
            return
        }
        switch label {
        case .message:
            textDataChannel = dataChannel
        case .file:
            fileDataChannel = dataChannel
        }
        delegate?.rtcClient(self, didOpen: dataChannel, label: label)
    }
}

extension RTCClient {
    
    enum DataChannelLabel: String {
        case message = "message"
        case file = "file"
    }
}

extension RTCClient {
    
    func setAudioEnabled(_ enabled: Bool) {
        audioTrack?.isEnabled = enabled
    }
    
    func setVideoEnabled(_ enabled: Bool) {
        videoTrack?.isEnabled = enabled
    }
}

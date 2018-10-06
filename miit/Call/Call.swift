//
//  Call.swift
//  miit
//
//  Created by Ken Sun on 2018/9/11.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation
import Async
import SwiftyJSON

protocol CallDelegate: class {
    
    func call(_ call: Call, didCreateLocalVideo capturer: RTCCameraVideoCapturer)
    
    func call(_ call: Call, didReceiveRemoteVideo track: RTCVideoTrack)
    
    func call(_ call: Call, didDisconnect error: Error?)    
}

protocol CallMessageDelegate: class {
    
    func callDidOpenTextChannel(_ call: Call)
    
    func callDidOpenFileChannel(_ call: Call)
    
    func call(_ call: Call, dldReceiveMessage json: JSON)
    
    func call(_ call: Call, didReceiveImage image: UIImage, meta: FileMeta)
    
    func call(_ call: Call, didReceiveVideo fileURL: URL, meta: FileMeta)
    
    func call(_ call: Call, didReceiveFile data: Data, meta: FileMeta, type: FileType)    
}

class Call: NSObject, RTCClientDelegate, RTCDataChannelDelegate {
    
    enum State {
        case new
        case opened
        case dialing
        case calling
        case hungUp
        case unavaliable
    }
    
    let roomID: String
    
    let token: String
    
    weak var delegate: CallDelegate?
    
    weak var messageDelegate: CallMessageDelegate?
    
    private(set) var isInitiator: Bool!
    
    private(set) var initiatorName: String?
    
    private(set) var peerName: String?
    
    var mitterName: String? { return isInitiator ? peerName : initiatorName }
    
    private(set) var client: RTCClient!
    
    private(set) var state: State = .new
    
    lazy var fileTransfer: FileTransfer = {
       return FileTransfer(channel: client.fileDataChannel!)
    }()
    
    init(roomID: String) {
        self.roomID = roomID
        self.token = TokenGenerator.get16()
    }
    
    func open(_ closure: @escaping (_ error: Error?) -> Void) {
        guard state == .new else {
            return
        }
        Api.openRoom(roomID: roomID, token: token) { [weak self] (isInitiator, error) in
            if error == nil {
                self?.isInitiator = isInitiator
                self?.state = .opened
                self?.heartbeat()
                if isInitiator == true {
                    self?.initiatorName = MyName
                } else {
                    self?.peerName = MyName
                }
            }
            closure(error)
        }
    }
    
    func kickOff() {
        state = .dialing
        client = RTCClient(isInitiator: isInitiator)
        client.delegate = self
        client.connect()
    }
    
    func waitForPeer() {
        Api.requestAnswer(roomID: roomID, token: token) { [weak self] (name, sdp, error) in
            if error == nil {
                let answerSdp = RTCSessionDescription(type: .answer, sdp: sdp!)
                self?.client.setRemoteAnswer(sdp: answerSdp)
                self?.peerName = name
            } else {
                self?.hangup(error: error)
            }
        }
    }
    
    func hangup(error: Error?) {
        state = .hungUp
        close()
        client.disconnect(error)
    }
    
    func close() {
        guard state != .unavaliable else {
            return
        }
        state = .unavaliable
        Api.closeRoom(roomID: roomID, token: token, nil)
    }
    
    private var heartbeatAllowed: [State] = [.opened, .dialing, .calling]
    private var keepAliveFailures = 0
    
    func heartbeat() {
        guard heartbeatAllowed.contains(state) else {
            return
        }
        Api.keepAlive(roomID: roomID, token: token) { [weak self] error in
            guard let wSelf = self else {
                return
            }
            if error != nil {
                if Api.getStatusCode(error: error!) == 404 || wSelf.keepAliveFailures + 1 >= 6 {
                    wSelf.hangup(error: error)
                    return
                }
                wSelf.keepAliveFailures += 1
            } else {
                wSelf.keepAliveFailures = 0
            }
            Async.main(after: 5, { [weak self] in
                self?.heartbeat()
            })
        }
    }
}

// MARK - RTCClient Delegate

extension Call {
    
    func rtcClient(_ client: RTCClient, didCreateLocalVideo capturer: RTCCameraVideoCapturer) {
        delegate?.call(self, didCreateLocalVideo: capturer)
    }
    
    func rtcClient(_ client: RTCClient, didReceiveRemoteVideo track: RTCVideoTrack) {
        delegate?.call(self, didReceiveRemoteVideo: track)
    }
    
    func rtcClient(_ client: RTCClient, didSetLocalOffer sdp: String) {
        Api.sendOffer(roomID: roomID, token: token, name: MyName, offerSdp: sdp) { [weak self] error in
            if error == nil {
                self?.waitForPeer()
            } else {
                self?.hangup(error: error)
            }
        }
    }
    
    func rtcClientShouldRequestRemoteOffer(_ client: RTCClient) {
        Api.requestOffer(roomID: roomID, token: token) { [weak self] (name, sdp, error) in
            if error == nil {
                let offerSdp = RTCSessionDescription(type: .offer, sdp: sdp!)
                self?.client.setRemoteOffer(sdp: offerSdp)
                self?.initiatorName = name
            } else {
                self?.hangup(error: error)
            }
        }
    }
    
    func rtcClient(_ client: RTCClient, didSetLocalAnswer sdp: String) {
        Api.sendAnswer(roomID: roomID, token: token, name: MyName, answerSdp: sdp) { [weak self] error in
            if error == nil {
                
            } else {
                self?.hangup(error: error)
            }
        }
    }
    
    func rtcClientDidFinishSdpExchange(_ client: RTCClient) {
        Api.requestIceCandidates(roomID: roomID, token: token, type: isInitiator ? .answer : .offer) { [weak self] (candidates, error) in
            if error == nil {
                self?.client.addIceCandidates(candidates ?? [])
                self?.state = .calling
            } else {
                self?.hangup(error: error)
            }
        }
    }
    
    func rtcClient(_client: RTCClient, didGather iceCandidates: [RTCIceCandidate]) {
        Api.sendIceCandidates(roomID: roomID, token: token, type: isInitiator ? .offer : .answer, candidates: iceCandidates) { [weak self] error in
            if error != nil {
                self?.hangup(error: error)
            }
        }
    }
    
    func rtcClient(_ client: RTCClient, didDisconnect error: Error?) {
        close()
        delegate?.call(self, didDisconnect: error)
    }
    
    func rtcClient(_ client: RTCClient, didOpen dataChannel: RTCDataChannel, label: RTCClient.DataChannelLabel) {
        dataChannel.delegate = self
        switch label {
        case .message:
            messageDelegate?.callDidOpenTextChannel(self)
        case .file:
            messageDelegate?.callDidOpenFileChannel(self)
        }
    }
}

// MARK: - Message And File

extension Call {
    
    func send(json: JSON) {
        guard let channel = client.textDataChannel, channel.readyState == .open else {
            NSLog("text data channel is not opened")
            return
        }
        guard let data = try? json.rawData() else {
            NSLog("can't create data for json \(json)")
            return
        }
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        channel.sendData(buffer)
    }
}

// MARK: - Data Channel Delegate

extension Call {
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        NSLog("\(dataChannel.label) data channel state is changed to \(dataChannel.readyState.rawValue)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        //NSLog("\(dataChannel.label) data channel did receive message")
        if dataChannel.label == "message" {
            // message
            if let json = try? JSON(data: buffer.data) {
                Async.main { [weak self] in
                    self?.messageDelegate?.call(self!, dldReceiveMessage: json)
                }
            } else {
                NSLog("parse json failedd")
            }
        } else if dataChannel.label == "file" {
            // file chunk
            if let result = receiveFileChunk(data: buffer.data) {
                Async.main { [weak self] in
                    if let img = result.image {
                        self?.messageDelegate?.call(self!, didReceiveImage: img, meta: result.meta)
                    } else if let video = result.filePath {
                        self?.messageDelegate?.call(self!, didReceiveVideo: URL(fileURLWithPath: video), meta: result.meta)
                    } else if let data = result.data {
                        self?.messageDelegate?.call(self!, didReceiveFile: data, meta: result.meta, type: result.type)
                    }
                }
            }
        }
    }
}

struct TokenGenerator {
    
    private static let base62chars = [Character]("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
    private static let maxBase : UInt32 = 62
    
    static func getCode(withBase base: UInt32 = maxBase, length: Int) -> String {
        var code = ""
        for _ in 0..<length {
            let random = Int(arc4random_uniform(min(base, maxBase)))
            code.append(base62chars[random])
        }
        return code
    }
    
    static func get16() -> String {
        return getCode(length: 16)
    }
}

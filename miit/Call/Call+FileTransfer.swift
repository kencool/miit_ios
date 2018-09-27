//
//  Call+FileTransfer.swift
//  miit
//
//  Created by Ken Sun on 2018/9/19.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import Foundation
import SwiftyJSON
import Async

// MARK: File Meta

typealias FileMeta = Dictionary<String,Any>

func getFileId(meta: FileMeta) -> UInt8 { return meta["fileid"] as! UInt8 }

func getFilename(meta: FileMeta) -> String { return meta["filename"] as! String }

func getFileSize(meta: FileMeta) -> Int { return meta["filesize"] as! Int }

// MARK: - File Type

let acceptableFileTypes = ["png", "jpg", "jpeg"]

func isFileAcceptable(meta: FileMeta) -> Bool {
    return acceptableFileTypes.contains(getFilename(meta: meta).pathExtension.lowercased())
}

// MARK: - File Transfer

protocol FileTransferDelegate: class {
    
    func fileTransfer(_ transfer: FileTransfer, file meta: FileMeta, didUpdate progress: CGFloat)
    
    func fileTransfer(_ transfer: FileTransfer, didFinishFile meta: FileMeta)
}

class FileTransfer {
    
    class Task {
        let meta: FileMeta
        
        // for sending file
        let data: Data?
        var chunkIndex: UInt32 = 0
        
        // for receiving file
        var receivedChunks: [Data] = []
        var inOrder: Int = 0
        
        init(meta: FileMeta) {
            self.meta = meta
            self.data = nil
        }
        
        init(meta: FileMeta, data: Data) {
            self.meta = meta
            self.data = data
        }
    }
    
    weak var delegate: FileTransferDelegate?
    
    let fileChannel: RTCDataChannel
    
    private(set) var fileSent: UInt8 = 0
    
    private var sendingFiles = [String:Task]()
    
    private var receivingFiles = [UInt8:Task]()
    
    private lazy var dateFormatter: DateFormatter =  {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    init(channel: RTCDataChannel) {
        self.fileChannel = channel
    }
    
    func requestSend(image: UIImage) -> FileMeta? {
        guard let data = UIImagePNGRepresentation(image) else {
            return nil
        }
        fileSent += 1
        let fileid = fileSent
        let filename = dateFormatter.string(from: Date()) + ".png"
        let meta: FileMeta = [
            "fileid": fileid,
            "filename": filename,
            "filesize": data.count
        ]
        sendingFiles[filename] = Task(meta: meta, data: data)
        return meta
    }
    
    func acceptSend(meta: FileMeta) {
        receivingFiles[meta["fileid"] as! UInt8] = Task(meta: meta)
    }
    
    func beginSend(filename: String) {
        if let task = sendingFiles[filename] {
            Async.background { [weak self] in
                self?.readFile(task: task)
            }
        }
    }
    
    private func readFile(task: Task) {
        var start: UInt64 = 0, end: UInt64 = 0
        while end != task.data!.count {
            // check file channel buffer
            guard isFileChannelBufferAvailable else {
                NSLog("file channel buffer is full, sleeping...")
                Async.background(after: backoff) { [weak self] in
                    self?.readFile(task: task)
                }
                return
            }
            start = UInt64(task.chunkIndex) * FileTransfer.chunkSize
            end = min(start + FileTransfer.chunkSize, UInt64(task.data!.count))
            NSLog("reada \(start) to \(end)")
            var data = Data(capacity: Int(end - start + 5))
            data.append(task.data![start..<end])
            data.append(task.meta["fileid"] as! UInt8)
            data.append(uint32: task.chunkIndex)
            task.chunkIndex += 1
            
            Async.main { [weak self] in
                let progress = CGFloat(end) / CGFloat(task.data!.count)
                self?.delegate?.fileTransfer(self!, file: task.meta, didUpdate: progress)
            }
            
            let buffer = RTCDataBuffer(data: data, isBinary: true)
            fileChannel.sendData(buffer)
        }
        // file transfer completed
        NSLog("send file completed, should send \(task.data!.count), actually sent \(end)")
        sendingFiles[task.meta["filename"] as! String] = nil
        
        Async.main { [weak self] in
            self?.delegate?.fileTransfer(self!, didFinishFile: task.meta)
        }
    }
    
    private var isFileChannelBufferAvailable: Bool {
            return fileChannel.bufferedAmount + FileTransfer.chunkSize <= FileTransfer.bufferSize
    }
    
    func cancelSend(filename: String) {
        sendingFiles[filename] = nil
    }
    
    func receiveChunk(data: Data) -> (FileMeta, Data)? {
        let fileId = data[data.count - 5]
        guard let chunkIndex = data.getUint32(index: data.count - 4) else {
            NSLog("can't get chunk index !!!!")
            return nil
        }
        NSLog("receive chunk \(chunkIndex)")
        guard let task = receivingFiles[fileId] else {
            NSLog("no receiving file for id \(fileId)")
            return nil
        }
        // insert chunk in order
        var order = Int(chunkIndex)
        if order == task.inOrder {
            task.receivedChunks.insert(data, at: order)
            task.inOrder += 1
        } else if task.receivedChunks.count == task.inOrder {
            task.receivedChunks.append(data)
        } else {
            for i in (task.inOrder..<task.receivedChunks.count).reversed() {
                let c = task.receivedChunks[i]
                if let ci = c.getUint32(index: c.count - 4), ci < chunkIndex {
                    order = i
                    break
                }
            }
            task.receivedChunks.insert(data, at: order)
        }
        // generate file if completed
        let meta = task.meta
        let fileSize = meta["filesize"] as! Int
        let totalChunks = Int(ceil(Double(fileSize) / Double(FileTransfer.chunkSize)))
        Async.main { [weak self] in
            let progress = CGFloat(task.receivedChunks.count) / CGFloat(totalChunks)
            self?.delegate?.fileTransfer(self!, file: meta, didUpdate: progress)
        }
        if task.receivedChunks.count >= totalChunks {
            // generate file
            var data = Data(capacity: fileSize)
            for v in task.receivedChunks {
                data.append(v[0..<v.count - 5])
            }
            NSLog("receive file completed, should receive \(fileSize), actually received \(data.count)")
            Async.main { [weak self] in
                self?.delegate?.fileTransfer(self!, didFinishFile: meta)
            }
            receivingFiles[meta["fileid"] as! UInt8] = nil
            return (meta, data)
        }
        return nil
    }
}

extension FileTransfer {
    
    static let  bufferSize: UInt64 = 16 * 1024 * 1024
    
    static let  backoffMs: UInt64 = 1000
    
    static let  chunkSize: UInt64 = 4096
    
    var backoff: Double { return Double(FileTransfer.backoffMs) / 1000.0 }
}

extension Call {
    
    func send(image: UIImage) {
        guard let channel = client.fileDataChannel, channel.readyState == .open else {
            NSLog("file data channel is not opened")
            return
        }
        
        guard let meta = fileTransfer.requestSend(image: image) else {
            NSLog("can't create data for image")
            return
        }
        let dict: [String:Any] = [
            "sender": MyName,
            "type": "fileinfo",
            "payload": meta
        ]
        send(json: JSON(dict))
    }
    
    func accept(meta: FileMeta) {
        fileTransfer.acceptSend(meta: meta)
        
        let dict: [String:Any] = [
            "sender": MyName,
            "type": "filetransfer",
            "payload": [
                "accepted": true,
                "filename": meta["filename"]
            ]
        ]
        send(json: JSON(dict))
    }
    
    func decline(meta: FileMeta) {
        let dict: [String:Any] = [
            "sender": MyName,
            "type": "filetransfer",
            "payload": [
                "accepted": false,
                "filename": meta["filename"]
            ]
        ]
        send(json: JSON(dict))
    }
    
    func receiveFileResponse(accepted: Bool, filename: String) {
        if accepted {
            fileTransfer.beginSend(filename: filename)
        } else {
            fileTransfer.cancelSend(filename: filename)
        }
    }
    
    func receiveFileChunk(data: Data) -> UIImage? {
        if let x = fileTransfer.receiveChunk(data: data) {
            let image = UIImage(data: x.1)
            return image
        }
        return nil
    }
}

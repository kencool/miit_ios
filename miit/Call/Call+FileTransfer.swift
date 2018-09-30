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

enum FileType: String {
    case png, jpg, jpeg
    case mp4, mov

    static let images: [FileType] = [.png, .jpg, .jpeg]
    
    static let videos: [FileType] = [.mp4, .mov]
    
    var isImage: Bool { return FileType.images.contains(self) }
    
    var isVideo: Bool { return FileType.videos.contains(self) }

    init? (meta: FileMeta) {
        guard let t = FileType(rawValue: getFilename(meta: meta).pathExtension.lowercased()) else {
            return nil
        }
        self = t
    }
}

func isFileAcceptable(meta: FileMeta) -> Bool {
    return FileType(meta: meta) != nil
}

// MARK: - File Transfer

protocol FileTransferDelegate: class {
    
    func fileTransfer(_ transfer: FileTransfer, file meta: FileMeta, didUpdate progress: CGFloat)
    
    func fileTransfer(_ transfer: FileTransfer, didFinishFile meta: FileMeta)
}

class FileTransfer {
    
    class Task {
        let meta: FileMeta
        let totalChunks: Int
        
        // for sending file
        let data: Data?
        var chunkIndex: UInt32 = 0
        
        // for receiving file
        var receivedChunks: [Data] = []
        var inOrder: Int = 0
        var fileOrder: Int = 0
        
        lazy var fileHandle: FileHandle = {
            return FileHandle(forWritingAtPath: filePath)!
        }()
        
        var filePath: String {
            let dirPath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
            let fullPath = dirPath.appendingPathComponent(getFilename(meta: meta))
            if !FileManager.default.fileExists(atPath: fullPath) {
                FileManager.default.createFile(atPath: fullPath, contents: nil, attributes: nil)
            }
            return fullPath
        }
        
        init(meta: FileMeta, data: Data? = nil) {
            self.meta = meta
            self.data = data
            self.totalChunks = Int(ceil(Double(getFileSize(meta: meta)) / Double(FileTransfer.chunkSize)))
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
            NSLog("read \(start) to \(end)")
            var data = Data(capacity: Int(end - start + 5))
            data.append(task.data![start..<end])
            data.append(getFileId(meta: task.meta))
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
        sendingFiles[getFilename(meta: task.meta)] = nil
        
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
    
    func receiveChunk(data: Data) -> (FileMeta, FileType, fileData: Data, filePath: String)? {
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
        
        // progress callback
        let meta = task.meta
        Async.main { [weak self] in
            let progress = CGFloat(task.receivedChunks.count) / CGFloat(task.totalChunks)
            self?.delegate?.fileTransfer(self!, file: meta, didUpdate: progress)
        }
        // generate file if completed
        if task.receivedChunks.count >= task.totalChunks {
            // generate file
            let fileSize = getFileSize(meta: meta)
            var data = Data(capacity: fileSize)
            for v in task.receivedChunks {
                data.append(v[0..<v.count - 5])
            }
            NSLog("receive file completed, should receive \(fileSize), actually received \(data.count)")
            Async.main { [weak self] in
                self?.delegate?.fileTransfer(self!, didFinishFile: meta)
            }
            receivingFiles[meta["fileid"] as! UInt8] = nil
            return (meta, FileType(meta: meta)!, data, task.filePath)
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
    
    func receiveFileChunk(data: Data) -> (image: UIImage?, filePath: String?)? {
        guard let x = fileTransfer.receiveChunk(data: data) else {
            return nil
        }
        if x.1.isImage {
            let image = UIImage(data: x.2)
            return (image, nil)
        } else if x.1.isVideo {
            try? x.2.write(to: URL(fileURLWithPath: x.3))
            return (nil, x.3)
        } else {
            NSLog("Unsupported file type.")
        }
        return nil
    }
}

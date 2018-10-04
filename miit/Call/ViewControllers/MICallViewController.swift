//
//  MICallViewController.swift
//  miit
//
//  Created by Ken Sun on 2018/9/10.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit
import SwiftyJSON
import UICircularProgressRing
import Async
import MobileCoreServices

class MICallViewController: UIViewController, CallViewDelegate, CallToolBarDelegate, ChatViewDelegate, CallMessageDelegate, FileTransferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    let call: Call
    
    var closeButton: UIButton!
    
    var infoButton: UIButton!
    
    var callView: CallView!
    
    var chatView: ChatView!
    
    var toolBar: CallToolBar!
    
    lazy var progressRing: UICircularProgressRing = {
        let ring = UICircularProgressRing()
        ring.outerRingColor = MIColor.royalBlue
        ring.innerRingColor = MIColor.seaGreen
        ring.outerRingWidth = 5
        ring.innerRingWidth = 5
        ring.fontColor = UIColor.white
        ring.startAngle = -90
        ring.font = UIFont.systemFont(ofSize: 12)
        self.view.addSubview(ring)
        ring.snp.makeConstraints({ make in
            make.width.height.equalTo(50)
            make.center.equalTo(self.view)
        })
        return ring
    }()
    
    // MARK: - Room Info Properties
    
    lazy var infoView: RoomInfoView = {
        let view = RoomInfoView()
        view.frame = CGRect(x: infoButton.x, y: infoButton.frame.maxY, width: 0, height: 0)
        self.view.addSubview(view)
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideRoomInfo))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    var isShowingInfo = false
    
    // MARK: - File Presentation Properties
    
    var filePresentView: FilePresentView?
    
    var filePresentShrinkFrame: CGRect?
    
    var filePresentShrinkMinimumScale: CGFloat?
    
    // MARK: - Gesture Handle Properties
    
    var isFullScreen: Bool = false {
        didSet {
            let alpha: CGFloat = isFullScreen ? 0.0 : 1.0
            UIView.animate(withDuration: 0.2) { [weak self] in
                self?.setFullscreenTransition(alpha: alpha)
            }
        }
    }
    
    var panStart: CGPoint = CGPoint.zero
    
    var panGesture: UIPanGestureRecognizer!
    
    var tapGesture: UITapGestureRecognizer!
    
    init(call: Call) {
        self.call = call
        super.init(nibName: nil, bundle: nil)
        call.messageDelegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        callView.startCall()
        registerNotifications()
    }

    deinit {
        unregisterNotifications()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //self.presentImage(UIImage(named: "1.JPG")!) // for test
        //self.presentPDF(try! Data(contentsOf: Bundle.main.url(forResource: "Sample", withExtension: "pdf")!), meta: ["filename":"Sample.pdf"])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        chatView.endEditing(true)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupViews() {
        self.view.backgroundColor = UIColor.black
        
        // call view
        callView = CallView(call: call)
        callView.delegate = self
        self.view.addSubview(callView)
        callView.snp.makeConstraints { make in
            make.edges.equalTo(self.view)
        }
        
        // chat view
        chatView = ChatView()
        chatView.delegate = self
        self.view.addSubview(chatView)
        chatView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self.view)
            make.height.equalTo(self.view.height / 3)
        }
        
        // close button
        closeButton = self.view.addButton(imageName: "close", self, action: #selector(closePressed))
        closeButton.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.topMargin)
            make.width.height.equalTo(50)
        }
        
        // info button
        infoButton = self.view.addButton(imageName: "room_info", self, action: #selector(toggleRoomInfo))
        infoButton.snp.makeConstraints { make in
            make.left.equalTo(closeButton.snp.right)
            make.top.equalTo(closeButton)
            make.width.height.equalTo(50)
        }
        
        // tool bar
        toolBar = CallToolBar()
        toolBar.delegate = self
        self.view.addSubview(toolBar)
        toolBar.snp.makeConstraints { make in
            make.top.equalTo(callView.localVideoView.snp.bottom).offset(8)
            make.rightMargin.equalTo(-8)
            make.width.equalTo(toolBar.width)
            make.height.equalTo(toolBar.height)
        }
        
        // detect pan to toggle full screen
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        self.view.addGestureRecognizer(panGesture)
        
        // detect tap to dismiss chat keyboard
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.view.addGestureRecognizer(tapGesture)
    }
}

extension MICallViewController {
    
    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow),
                                               name: .UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide),
                                               name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self,selector: #selector(keyboardWillChangeFrame(_:)),
                                               name: .UIKeyboardWillChangeFrame, object: nil)
    }
    
    func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UI Actions

extension MICallViewController {
    
    @objc func closePressed() {
        callView.stopCall()
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - CallView Delegate

extension MICallViewController {
    
    func callView(_ callView: CallView, didStop error: Error?) {
        if error != nil {
            self.dismiss(animated: true, completion: nil)
            self.presentingViewController?.presentAlertNotice(title: "Disconnected", message: error!.localizedDescription)
        }
    }
}

// MARK: - ChatView Delegate

extension MICallViewController {
    
    func chatView(_ chatView: ChatView, didSend message: Message) {
        message.textColor = call.isInitiator ? MIColor.royalBlue : MIColor.seaGreen
        call.send(json: message.json)
    }
}

// MARK: - Call Message Delegate

extension MICallViewController {
    
    func callDidOpenTextChannel(_ call: Call) {
        // do nothing
    }
    
    func callDidOpenFileChannel(_ call: Call) {
        // do nothing
    }
    
    func call(_ call: Call, dldReceiveMessage json: JSON) {
        if json["type"].string == "message" {
            // chat message
            let message = Message(json: json)
            message.textColor = call.isInitiator ? MIColor.seaGreen : MIColor.royalBlue
            chatView.insert(message: message)
        } else if json["type"].string == "fileinfo" {
            // file transfer request
            guard let meta = json["payload"].dictionaryObject else {
                return
            }
            
            guard isFileAcceptable(meta: meta) else {
                self.presentAlertNotice(title: "Unacceptable File", message: "Sorry, \(call.mitterName ?? "peer") wants to share an unsupported file. We only support receiving image files now.")
                call.decline(meta: meta)
                return
            }
            self.presentAlertYesOrNo(title: (call.mitterName ?? "Peer") + " wants to share a file", message: getFilename(meta: meta), yes: { [weak self] _ in
                self?.progressRing.isHidden = false
                self?.call.fileTransfer.delegate = self
                self?.call.accept(meta: meta)
            }) { [weak self] _ in
                self?.call.decline(meta: meta)
            }
        } else if json["type"].string == "filetransfer" {
            // file transfer agreement
            let accepted = json["payload"]["accepted"].boolValue
            if accepted {
                self.call.fileTransfer.delegate = self
                self.progressRing.isHidden = false
                self.progressRing.resetProgress()
            }
            self.call.receiveFileResponse(accepted: accepted,
                                          filename: json["payload"]["filename"].stringValue)
        }
    }
    
    func call(_ call: Call, didReceiveImage image: UIImage, meta: FileMeta) {
        presentImage(image, meta: meta)
    }
    
    func call(_ call: Call, didReceiveVideo fileURL: URL, meta: FileMeta) {
        presentVideo(fileURL, meta: meta)
    }
    
    func call(_ call: Call, didReceiveFile data: Data, meta: FileMeta, type: FileType) {
        switch type {
        case .pdf:
            presentPDF(data, meta: meta)
        default:
            break
        }
    }
}

// MARK: File Transfer Delegate

extension MICallViewController {
    
    func fileTransfer(_ transfer: FileTransfer, file meta: FileMeta, didUpdate progress: CGFloat) {
        progressRing.value = progress * 100
    }
    
    func fileTransfer(_ transfer: FileTransfer, didFinishFile meta: FileMeta) {
        progressRing.isHidden = true
    }
}

// MARK: - Tool Bar Delegate

extension MICallViewController: UIDocumentPickerDelegate {
    
    func callToolBarDidSelectCloud(_ toolBar: CallToolBar) {
        let picker = UIDocumentPickerViewController(documentTypes: Cloud.pickDocumentTypes, in: .open)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        self.present(picker, animated: true, completion: nil)
    }
    
    func callToolBarDidSelectPhoto(_ toolBar: CallToolBar) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        picker.allowsEditing = false
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    func callToolBar(_ toolBar: CallToolBar, didSwitchVideo on: Bool) {
        call.client.setVideoEnabled(on)
        callView.setPreviewMasked(on: !on)
    }
    
    func callToolBar(_ toolBar: CallToolBar, didSwitchAudio on: Bool) {
        call.client.setAudioEnabled(on)
    }
}

extension MICallViewController {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard controller.documentPickerMode == .open, let url = urls.first, url.startAccessingSecurityScopedResource() else {
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        call.send(fileURL: url)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        self.dismiss(animated: true, completion: nil)
        
        switch info[UIImagePickerControllerMediaType] as? String {
        case "public.movie":
            let url = info[UIImagePickerControllerMediaURL] as! URL
            call.send(fileURL: url)
            
        case "public.image":
            let image: UIImage = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as! UIImage
            call.send(image: UIImage.fixImageOrientation(image))
        default:
            return
        }
        self.presentAlertNotice(title: "Send File", message: "Waiting for \(call.mitterName ?? "peer") accept.")
    }
}

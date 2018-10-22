//
//  MICallEntryViewController.swift
//  miit
//
//  Created by Ken Sun on 2018/9/10.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit
import SnapKit
import SwiftEntryKit

class MICallEntryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var entryText: MICallEntryTextField!
    
    private var nameButton: UIButton!
    
    private var callButton: UIButton!

    private var cacheTitleLabel: UILabel!
    
    private var cacheTableView: UITableView!
    
    private lazy var connectingLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "Connecting.....".localized()
        label.sizeToFit()
        label.isHidden = true
        self.view.addSubview(label)
        label.snp.makeConstraints{ make in
            make.center.equalTo(callButton)
            //make.bottom.equalTo(callButton.snp.top).offset(-8)
        }
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        
        // detect tap to dismiss input text field
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showWelcomeIfNeeded()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupViews() {
        self.view.backgroundColor = MIColor.gray
        
        // entry id text
        self.entryText = MICallEntryTextField(frame: CGRect.zero)
        self.view.addSubview(entryText)
        entryText.snp.makeConstraints { make in
            make.leftMargin.equalTo(30)
            make.rightMargin.equalTo(-30)
            make.height.equalTo(40)
            make.centerY.equalTo(self.view)
        }
        
        // name button
        nameButton = self.view.addButton(title: MyName, self, action: #selector(namePressed))
        nameButton.setTitleColor(UIColor.white, for: .normal)
        nameButton.setTitleColor(UIColor.lightGray, for: .highlighted)
        nameButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        nameButton.shadowColor = UIColor.black
        nameButton.shadowOffset = CGSize(width: 1, height: 1)
        nameButton.shadowOpacity = 1
        nameButton.shadowRadius = 1
        nameButton.snp.makeConstraints { make in
            make.top.equalTo(entryText.snp.bottom).offset(8)
            make.left.equalTo(entryText).offset(4)
        }
        // cache title
        cacheTitleLabel = UILabel()
        cacheTitleLabel.text = "room_cache_title".localized()
        cacheTitleLabel.textColor = UIColor.lightGray
        cacheTitleLabel.font = UIFont.systemFont(ofSize: 16)
        cacheTitleLabel.isHidden = CallHistory.latestRoomIDs.count == 0
        cacheTitleLabel.sizeToFit()
        self.view.addSubview(cacheTitleLabel)
        cacheTitleLabel.snp.makeConstraints { make in
            make.leftMargin.equalTo(45)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.topMargin).offset(20)
        }
        
        // joined room cache
        cacheTableView = UITableView(frame: CGRect.zero, style: .plain)
        cacheTableView.backgroundColor = UIColor.clear
        cacheTableView.separatorStyle = .none
        cacheTableView.showsVerticalScrollIndicator = false
        cacheTableView.dataSource = self
        cacheTableView.delegate = self
        self.view.addSubview(cacheTableView)
        cacheTableView.snp.makeConstraints { make in
            make.left.right.equalTo(entryText)
            make.top.equalTo(cacheTitleLabel.snp.bottom).offset(8)
            make.bottom.equalTo(entryText.snp.top).offset(-20)
        }
        
        // call button
        callButton = self.view.addButton(title: "Go miit !".localized(), self, action: #selector(callPressed))
        callButton.setTitleColor(UIColor.white, for: .normal)
        callButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottomMargin).offset(-50)
        }
    }
    
    @objc func namePressed() {
        let alert = UIAlertController(title: "display_name".localized(), message: "display_name_message".localized(), preferredStyle: .alert)
        let ok = UIAlertAction(title: "Confirm".localized(), style: .default) { [weak self]  _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else  {
                return
            }
            self?.nameButton.setTitle(name, for: .normal)
            MyName = name
        }
        alert.addAction(ok)
        alert.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.placeholder = "your name".localized()
            textField.text = MyName
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func callPressed() {
        var roomID = entryText.text
        if roomID.isEmpty {
            // randomize room ID instead of blocking user
            roomID = String(abs((UIDevice.current.name.hashValue + Int(arc4random_uniform(10000))) % 10000))
        }
        /*
        guard !roomID.isEmpty else {
            Alert.show(title: "Invalid Room", message: "Room ID can't be empty.") { [weak self] _ in
                self?.entryText.entryText.becomeFirstResponder()
            }
            
            return
        }
 */
        guard roomID.count <= 16 else {
            Alert.showError(title: "Invalid Room".localized(), message: "room_id_too_long".localized())
           return
        }
        guard connectingLabel.isHidden else {
            return
        }
        connectingLabel.isHidden = false
        callButton.isHidden = true
        
        let call = Call(roomID: roomID)
        call.open { [weak self] error in
            if error == nil {
                let vc = MICallViewController(call: call)
                self?.present(vc, animated: true) { [weak self] in
                    // update joined room list sliently
                    CallHistory.add(roomId: roomID)
                    self?.cacheTableView.reloadData()
                    self?.cacheTableView.contentOffset = CGPoint.zero
                    if self?.cacheTitleLabel.isHidden == true {
                        self?.cacheTitleLabel.isHidden = false
                    }
                }
            } else {
                Alert.showError(title: "open_room_failed".localized(), message: error!.localizedDescription)
            }
            self?.connectingLabel.isHidden = true
            self?.callButton.isHidden = false
        }
    }

    @objc func handleTap() {
        entryText.endEditing(true)
    }
}

// MARK: - Table View Data Source & Delegate

extension MICallEntryViewController {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CallHistory.latestRoomIDs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "RoomCacheCell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "RoomCacheCell")
            cell?.selectionStyle = .none
            cell?.backgroundColor = UIColor.clear
            cell?.textLabel?.textColor = UIColor.lightGray
            cell?.textLabel?.font = UIFont.systemFont(ofSize: 16)
        }
        cell?.textLabel?.text = CallHistory.latestRoomIDs[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        entryText.entryText.text = CallHistory.latestRoomIDs[indexPath.row]
        callPressed()
    }
}

// MARK: -

class MICallEntryTextField: UIView, UITextFieldDelegate {
    
    fileprivate var entryText: UITextField!
    
    var text: String { get { return entryText.text ?? "" } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.entryText = UITextField(frame: CGRect.zero)
        self.entryText.delegate = self
        self.entryText.borderStyle = .none
        self.entryText.autocorrectionType = .no
        self.entryText.autocapitalizationType = .none
        self.entryText.clearButtonMode = .always
        self.entryText.keyboardType = .asciiCapable
        self.entryText.textColor = UIColor.white
        self.entryText.returnKeyType = .done
        self.entryText.attributedPlaceholder = NSAttributedString(string: "room_id_entry_placeholder".localized(),
                                                                  attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightGray,
                                                                               NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14)])
        self.addSubview(entryText)
        entryText.snp.makeConstraints { (make) in
            make.topMargin.equalTo(0)
            make.height.equalTo(40)
            make.leadingMargin.equalTo(8)
            make.trailingMargin.equalTo(0)
        }
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.lightGray.cgColor
        self.layer.cornerRadius = 2.0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - Welcome

extension MICallEntryViewController {
    
    func showWelcomeIfNeeded() {
        guard UserDefaults.standard.bool(forKey: "welcome") == false else {
            return
        }
        UserDefaults.standard.set(true, forKey: "welcome")
        // attributes
        var attributes = EKAttributes.centerFloat
        attributes.hapticFeedbackType = .success
        attributes.displayDuration = .infinity
        attributes.entryBackground = .gradient(gradient: .init(colors: [MIColor.royalBlue, MIColor.seaGreen], startPoint: .zero, endPoint: CGPoint(x: 1, y: 1)))
        attributes.screenBackground = .color(color: UIColor(white: 50.0/255.0, alpha: 0.3))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 8))
        attributes.screenInteraction = .dismiss
        attributes.entryInteraction = .absorbTouches
        attributes.scroll = .enabled(swipeable: true, pullbackAnimation: .jolt)
        attributes.roundCorners = .all(radius: 8)
        attributes.entranceAnimation = .init(translate: .init(duration: 0.7, spring: .init(damping: 0.7, initialVelocity: 0)),
                                             scale: .init(from: 0.7, to: 1, duration: 0.4, spring: .init(damping: 1, initialVelocity: 0)))
        attributes.exitAnimation = .init(translate: .init(duration: 0.2))
        attributes.popBehavior = .animated(animation: .init(translate: .init(duration: 0.35)))
        attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)
        attributes.positionConstraints.maxSize = .init(width: .constant(value: UIScreen.main.bounds.width), height: .intrinsic)
        // popup content
        let title = EKProperty.LabelContent(text: "welcome".localized(), style: EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 24), color: UIColor.white, alignment: .center))
        let description = EKProperty.LabelContent(text: "welcome_message".localized(), style: EKProperty.LabelStyle(font: UIFont.systemFont(ofSize: 16), color: UIColor.lightText, alignment: .center))
        let button = EKProperty.ButtonContent(label: .init(text: "welcome_go".localized(), style: .init(font: UIFont.systemFont(ofSize: 16), color: MIColor.gray)), backgroundColor: UIColor.white, highlightedBackgroundColor: MIColor.gray.withAlphaComponent(0.05))
        // message view
        let message = EKPopUpMessage(themeImage: nil, title: title, description: description, button: button) {
            SwiftEntryKit.dismiss()
        }
        let view = EKPopUpMessageView(with: message)
        // display
        SwiftEntryKit.display(entry: view, using: attributes)
    }
}

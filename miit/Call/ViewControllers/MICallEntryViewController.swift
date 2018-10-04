//
//  MICallEntryViewController.swift
//  miit
//
//  Created by Ken Sun on 2018/9/10.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit
import SnapKit

class MICallEntryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private var entryText: MICallEntryTextField!
    
    private var nameButton: UIButton!
    
    private var callButton: UIButton!
    
    private var cacheTableView: UITableView!
    
    private lazy var connectingLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "Connecting....."
        label.sizeToFit()
        label.isHidden = true
        self.view.addSubview(label)
        label.snp.makeConstraints{ make in
            make.centerX.equalTo(callButton)
            make.bottom.equalTo(callButton.snp.top).offset(-8)
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
            make.width.equalTo(Screen.width * 2/3)
            make.height.equalTo(40)
            make.center.equalTo(self.view)
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
            make.top.equalTo(view.safeAreaLayoutGuide.snp.topMargin).offset(8)
            make.bottom.equalTo(entryText.snp.top).offset(-20)
        }
        
        // call button
        self.callButton = self.view.addButton(imageName: "click", self, action: #selector(callPressed))
        callButton.snp.makeConstraints { make in
            make.centerX.equalTo(self.view)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottomMargin).offset(-50)
        }
    }
    
    @objc func namePressed() {
        let alert = UIAlertController(title: "Display Name", message: "Your display name in the room.", preferredStyle: .alert)
        let ok = UIAlertAction(title: "Confirm", style: .default) { [weak self]  _ in
            guard let name = alert.textFields?.first?.text, !name.isEmpty else  {
                return
            }
            self?.nameButton.setTitle(name, for: .normal)
            MyName = name
        }
        alert.addAction(ok)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addTextField { textField in
            textField.placeholder = "your name"
            textField.text = MyName
        }
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func callPressed() {
        let roomID = entryText.text
        guard !roomID.isEmpty else {
            Alert.show(title: "Invalid Room", message: "Room ID can't be empty.")
            return
        }
        guard roomID.count <= 16 else {
            Alert.show(title: "Invalid Room", message: "Room ID is too long. Maximum is 16 characters.")
            return
        }
        guard connectingLabel.isHidden else {
            return
        }
        connectingLabel.isHidden = false
        
        let call = Call(roomID: roomID)
        call.open { [weak self] error in
            if error == nil {
                let vc = MICallViewController(call: call)
                self?.present(vc, animated: true) { [weak self] in
                    // update joined room list sliently
                    CallHistory.add(roomId: roomID)
                    self?.cacheTableView.reloadData()
                    self?.cacheTableView.contentOffset = CGPoint.zero
                }
            } else {
                self?.presentAlertNotice(title: "Open Room Failed", message: error!.localizedDescription)
            }
            self?.connectingLabel.isHidden = true
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
        self.entryText.attributedPlaceholder = NSAttributedString(string: "Room ID", attributes: [NSAttributedStringKey.foregroundColor: UIColor.lightGray,
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

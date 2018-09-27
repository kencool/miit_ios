//
//  ChatView.swift
//  miit
//
//  Created by Ken Sun on 2018/9/27.
//  Copyright © 2018年 Ken Sun. All rights reserved.
//

import UIKit

protocol ChatViewDelegate: class {
    
    func chatView(_ chatView: ChatView, didSend message: Message)
}

class ChatView: UIView, UITextViewDelegate, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: ChatViewDelegate?
    
    fileprivate(set) var chatIcon: UIImageView!
    
    fileprivate(set) var inputTextView: UITextView!
    
    fileprivate(set) var messageTableView: UITableView!
    
    private var sendButton: UIButton!
    
    private var messages = [Message]()
    
    init() {
        super.init(frame: CGRect.zero)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        self.backgroundColor = UIColor.clear
        
        // input text
        inputTextView = UITextView(frame: CGRect.zero, textContainer: nil)
        inputTextView.delegate = self
        inputTextView.backgroundColor = UIColor.clear
        inputTextView.font = UIFont.systemFont(ofSize: 14)
        inputTextView.borderWidth = 0.5
        inputTextView.borderColor = UIColor.lightGray
        inputTextView.textColor = UIColor.white
        inputTextView.tintColor = UIColor.lightGray
        inputTextView.shadowColor = UIColor.black
        inputTextView.shadowOffset = CGSize(width: 2, height: 2)
        inputTextView.shadowOpacity = 1
        inputTextView.shadowRadius = 2
        self.addSubview(inputTextView)
        inputTextView.snp.makeConstraints { (make) in
            make.height.equalTo(40)
            make.leadingMargin.equalTo(8)
            make.trailingMargin.equalTo(-8)
            make.bottomMargin.equalTo(-8)
        }
        
        // chat icon
        chatIcon = UIImageView(image: UIImage(named: "chat"))
        chatIcon.contentMode = .scaleAspectFit
        self.addSubview(chatIcon)
        chatIcon.snp.makeConstraints { make in
            make.left.equalTo(inputTextView)
            make.bottom.equalTo(inputTextView.snp.top).offset(-5)
            make.width.height.equalTo(30)
        }
        
        // send button
        sendButton = self.addButton(title: "Send", self, action: #selector(sendPressed))
        sendButton.setTitleColor(UIColor.white, for: .normal)
        sendButton.shadowColor = UIColor.black
        sendButton.shadowOffset = CGSize(width: 2, height: 2)
        sendButton.shadowOpacity = 1
        sendButton.shadowRadius = 2
        sendButton.snp.makeConstraints { make in
            make.left.equalTo(inputTextView.snp.right).offset(8)
            make.centerY.equalTo(inputTextView)
        }
        
        // message table
        messageTableView = UITableView(frame: CGRect.zero, style: .plain)
        messageTableView.showsVerticalScrollIndicator = false
        messageTableView.showsHorizontalScrollIndicator = false
        messageTableView.backgroundColor = UIColor.clear
        messageTableView.separatorStyle = .none
        messageTableView.clipsToBounds = true
        messageTableView.dataSource = self
        messageTableView.delegate = self
        messageTableView.isScrollEnabled = false
        messageTableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        self.addSubview(messageTableView)
        messageTableView.snp.makeConstraints { make in
            make.left.equalTo(inputTextView)
            make.right.equalTo(self).offset(-8)
            make.bottom.equalTo(inputTextView.snp.top).offset(-8)
            make.height.equalTo(0)
        }
    }
    
    @objc func sendPressed() {
        //inputTextView.resignFirstResponder()
        
        guard let text = inputTextView.text, !text.isEmpty else {
            return
        }
        let message = Message(username: MyName, text: text)
        delegate?.chatView(self, didSend: message)
        insert(message: message)
        
        inputTextView.text = ""
    }
    
    func insert(message: Message) {
        messageTableView.beginUpdates()
        messages.append(message)
        messageTableView.insertRows(at: [IndexPath(row: messages.count - 1, section: 0)], with: .none)
        messageTableView.endUpdates()
        messageTableView.layoutIfNeeded()
        
        if !messageTableView.isScrollEnabled {
            let newHeight = min(messageTableView.contentSize.height, messageTableView.frame.maxY)
            UIView.animate(withDuration: 0.1) { [weak self] in
                guard let wSelf = self else { return }
                wSelf.messageTableView.snp.updateConstraints { make in
                    make.height.equalTo(newHeight)
                }
                wSelf.layoutIfNeeded()
            }
            if newHeight == messageTableView.frame.maxY {
                messageTableView.isScrollEnabled = true
            }
            if !chatIcon.isHidden {
                chatIcon.isHidden = true
            }
        } else {
            messageTableView.scrollToBottom()
        }
    }
}

// MARK: - UITextView Delegate

extension ChatView {
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.isEmpty && sendButton.x < self.width {
            // hide send
            UIView.animate(withDuration: 0.2) { [weak self] in
                textView.snp.updateConstraints { make in
                    make.trailingMargin.equalTo(-8)
                }
                self?.layoutIfNeeded()
            }
        } else if !textView.text.isEmpty && sendButton.x >= self.width {
            // show send
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let wSelf = self  else {
                    return
                }
                textView.snp.updateConstraints { make in
                    make.trailingMargin.equalTo(-(wSelf.sendButton.width + 16))
                }
                wSelf.layoutIfNeeded()
            }
        }
    }
}

// MARK: - UITableView Data Source & Delegate

extension ChatView {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") as! MessageCell
        let message = messages[indexPath.row]
        cell.textLabel?.attributedText = message.attributedText
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let message = messages[indexPath.row]
        let bounds = message.attributedText.boundingRect(with: CGSize(width: tableView.width, height: CGFloat.greatestFiniteMagnitude),
                                                         options: .usesLineFragmentOrigin, context: nil)
        let height = bounds.height + 10
        return height
    }
}

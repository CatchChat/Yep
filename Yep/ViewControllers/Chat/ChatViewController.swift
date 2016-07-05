//
//  ChatViewController.swift
//  Yep
//
//  Created by NIX on 16/6/16.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import AsyncDisplayKit

class ChatViewController: BaseViewController {

    var conversation: Conversation!
    var realm: Realm!

    lazy var messages: Results<Message> = {
        return messagesOfConversation(self.conversation, inRealm: self.realm)
    }()

    let messagesBunchCount = 20
    var displayedMessagesRange = NSRange()

    lazy var tableNode: ASTableNode = {
        let node = ASTableNode()
        node.dataSource = self
        node.delegate = self
        return node
    }()

    deinit {
        tableNode.dataSource = nil
        tableNode.delegate = nil

        println("deinit ChatViewController")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableNode.frame = view.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            view.addSubview(tableNode.view)
        }

        realm = conversation.realm!

        do {
            if messages.count >= messagesBunchCount {
                displayedMessagesRange = NSRange(location: messages.count - messagesBunchCount, length: messagesBunchCount)
            } else {
                displayedMessagesRange = NSRange(location: 0, length: messages.count)
            }
        }
    }
}

extension ChatViewController: ASTableDataSource, ASTableDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return displayedMessagesRange.length
    }

    func tableView(tableView: ASTableView, nodeForRowAtIndexPath indexPath: NSIndexPath) -> ASCellNode {

        guard let message = messages[safe: (displayedMessagesRange.location + indexPath.item)] else {
            let node = ChatSectionDateCellNode()
            node.configure(withText: "🐌🐌🐌")
            return node
        }

        guard let mediaType = MessageMediaType(rawValue: message.mediaType) else {
            let node = ChatSectionDateCellNode()
            node.configure(withText: "🐌🐌")
            return node
        }

        if case .SectionDate = mediaType {
            let node = ChatSectionDateCellNode()
            node.configure(withMessage: message)
            return node
        }

        guard let sender = message.fromFriend else {

            if message.blockedByRecipient {
                // TODO:
            }

            let node = ChatSectionDateCellNode()
            node.configure(withText: "🐌")
            return node
        }

        if sender.friendState != UserFriendState.Me.rawValue { // from Friend

            switch mediaType {

            case .Text:

                let node = ChatLeftTextCellNode()
                node.configure(withMessage: message)
                return node

            case .Image:

                let node = ChatLeftImageCellNode()
                node.configure(withMessage: message)
                return node

            default:
                let node = ChatLeftTextCellNode()
                node.configure(withMessage: message)
                return node
            }

        } else { // from Me

            switch mediaType {

            case .Text:

                let node = ChatRightTextCellNode()
                node.configure(withMessage: message)
                return node

            default:
                let node = ChatRightTextCellNode()
                node.configure(withMessage: message)
                return node
            }
        }
    }
}


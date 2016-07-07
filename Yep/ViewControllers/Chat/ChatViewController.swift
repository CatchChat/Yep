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

    var previewTransitionViews: [UIView?]?
    var previewAttachmentPhotos: [PreviewAttachmentPhoto] = []
    var previewMessagePhotos: [PreviewMessagePhoto] = []

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

        let scrollToBottom: dispatch_block_t = { [weak self] in
            guard let strongSelf = self else {
                return
            }
            guard strongSelf.displayedMessagesRange.length > 0 else {
                return
            }
            strongSelf.tableNode.view?.beginUpdates()
            strongSelf.tableNode.view?.reloadData()
            strongSelf.tableNode.view?.endUpdatesAnimated(false) { [weak self] success in
                guard success, let strongSelf = self else {
                    return
                }
                let bottomIndexPath = NSIndexPath(
                    forRow: strongSelf.displayedMessagesRange.length - 1,
                    inSection: Section.Messages.rawValue
                )
                strongSelf.tableNode.view?.scrollToRowAtIndexPath(bottomIndexPath, atScrollPosition: .Bottom, animated: false)
            }
        }
        delay(0, work: scrollToBottom)
    }
}

extension ChatViewController: ASTableDataSource, ASTableDelegate {

    enum Section: Int {
        case LoadPrevious
        case Messages
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 2
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let section = Section(rawValue: section) else {
            return 0
        }

        switch section {

        case .LoadPrevious:
            return 1

        case .Messages:
            return displayedMessagesRange.length
        }
    }

    func tableView(tableView: ASTableView, nodeForRowAtIndexPath indexPath: NSIndexPath) -> ASCellNode {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:

            let node = ChatLoadingCellNode()
            return node

        case .Messages:

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
                    let node = ChatPromptCellNode()
                    node.configure(withMessage: message, promptType: .BlockedByRecipient)
                    return node
                }

                let node = ChatSectionDateCellNode()
                node.configure(withText: "🐌")
                return node
            }

            if sender.friendState != UserFriendState.Me.rawValue { // from Friend

                if message.deletedByCreator {
                    let node = ChatPromptCellNode()
                    node.configure(withMessage: message, promptType: .RecalledMessage)
                    return node
                }

                switch mediaType {

                case .Text:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message)
                    return node

                case .Image:

                    let node = ChatLeftImageCellNode()
                    node.configure(withMessage: message)
                    node.tapImageAction = { [weak self] in
                        self?.tryPreviewMediaOfMessage(message)
                    }
                    return node

                case .Audio:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Audio")
                    return node

                case .Video:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Video")
                    return node

                case .Location:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Location")
                    return node

                case .SocialWork:

                    let node = ChatLeftTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious SocialWork")
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

                case .Image:

                    let node = ChatRightImageCellNode()
                    node.configure(withMessage: message)
                    node.tapImageAction = { [weak self] in
                        self?.tryPreviewMediaOfMessage(message)
                    }
                    return node

                case .Audio:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Audio")
                    return node

                case .Video:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Video")
                    return node

                case .Location:

                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message, text: "Mysterious Location")
                    return node

                default:
                    let node = ChatRightTextCellNode()
                    node.configure(withMessage: message)
                    return node
                }
            }
        }
    }

    func tableView(tableView: ASTableView, willDisplayNodeForRowAtIndexPath indexPath: NSIndexPath) {

        guard let section = Section(rawValue: indexPath.section) else {
            fatalError("Invalid section!")
        }

        switch section {

        case .LoadPrevious:
            let node = tableView.nodeForRowAtIndexPath(indexPath) as? ChatLoadingCellNode
            node?.isLoading = true

        case .Messages:
            break
        }
    }
}


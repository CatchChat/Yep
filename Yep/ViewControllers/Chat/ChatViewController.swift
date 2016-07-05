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

    /*
    lazy var collectionNode: ASCollectionNode = {
        let layout = ConversationLayout()
        let node = ASCollectionNode(collectionViewLayout: layout)
        node.backgroundColor = UIColor.lightGrayColor()

        node.dataSource = self
        node.delegate = self

        return node
    }()
    */

    deinit {
        tableNode.dataSource = nil
        tableNode.delegate = nil
        /*
        collectionNode.dataSource = nil
        collectionNode.delegate = nil
        */
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableNode.frame = view.bounds
        //collectionNode.frame = view.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            view.addSubview(tableNode.view)
            //view.addSubview(collectionNode.view)
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
            fatalError()
        }

        guard let mediaType = MessageMediaType(rawValue: message.mediaType) else {
            fatalError()
        }

        switch mediaType {

        case .SectionDate:
            let node = ChatSectionDateCellNode()
            node.configure(withMessage: message)
            return node

        default:
            let node = ChatLeftTextCellNode()
            node.configure(withMessage: message)
            return node
        }
    }
}

/*
extension ChatViewController: ASCollectionDataSource, ASCollectionDelegate {

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {

        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

        return 20
    }

    func collectionView(collectionView: ASCollectionView, nodeForItemAtIndexPath indexPath: NSIndexPath) -> ASCellNode {

        let node = ChatBaseCellNode()
        node.backgroundColor = UIColor.yepTintColor()
        return node
    }
}
*/

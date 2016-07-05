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

    lazy var collectionNode: ASCollectionNode = {
        let layout = ConversationLayout()
        let node = ASCollectionNode(collectionViewLayout: layout)
        node.backgroundColor = UIColor.lightGrayColor()

        node.dataSource = self
        node.delegate = self

        return node
    }()

    deinit {
        collectionNode.dataSource = nil
        collectionNode.delegate = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionNode.frame = view.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            //view.addSubnode(collectionNode)
            view.addSubview(collectionNode.view)
        }
    }
}

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


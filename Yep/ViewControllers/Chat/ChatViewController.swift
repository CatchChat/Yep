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
    }
}

extension ChatViewController: ASTableDataSource, ASTableDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {

        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return 20
    }

    func tableView(tableView: ASTableView, nodeForRowAtIndexPath indexPath: NSIndexPath) -> ASCellNode {

        let node = ChatBaseCellNode()
        node.backgroundColor = UIColor.yepTintColor()
        return node
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

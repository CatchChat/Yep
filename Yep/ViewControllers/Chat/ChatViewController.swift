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
        node.backgroundColor = UIColor.redColor()
        return node
    }()

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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

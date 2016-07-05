//
//  ChatLeftTextCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import AsyncDisplayKit

class ChatLeftTextCellNode: ChatBaseCellNode {

    lazy var textNode = ASTextNode()

    override init() {
        super.init()

        addSubnode(textNode)
        textNode.backgroundColor = UIColor.greenColor()
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        return CGSize(width: constrainedSize.width, height: 50)
    }

    override func layout() {
        super.layout()

        avatarImageNode.frame = CGRect(x: 15, y: 0, width: 40, height: 40)
        textNode.frame = CGRect(x: 65, y: 0, width: 120, height: 40)
    }
}


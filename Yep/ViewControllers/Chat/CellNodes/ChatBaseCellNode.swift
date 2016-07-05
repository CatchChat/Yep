//
//  ChatBaseCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import AsyncDisplayKit

class ChatBaseCellNode: ASCellNode {

    lazy var nameLabel = ASTextNode()
    lazy var avatarImageView = ASImageNode()

    override init() {
        super.init()

        //addSubnode(nameLabel)
        addSubnode(avatarImageView)
        avatarImageView.backgroundColor = UIColor.redColor()
    }

    override func layout() {
        super.layout()

        avatarImageView.frame = CGRect(x: 15, y: 0, width: 40, height: 40)
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {
        return CGSize(width: 100, height: 50)
    }
}

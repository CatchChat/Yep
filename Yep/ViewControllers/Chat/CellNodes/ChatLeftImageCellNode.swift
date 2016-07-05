//
//  ChatLeftImageCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

class ChatLeftImageCellNode: ChatLeftBaseCellNode {

    lazy var imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .ScaleAspectFill
        return node
    }()

    override init() {
        super.init()

        addSubnode(imageNode)
        imageNode.backgroundColor = UIColor.cyanColor()
    }

    func configure(withMessage message: Message, messageImagePreferredWidth: CGFloat, messageImagePreferredHeight: CGFloat, messageImagePreferredAspectRatio: CGFloat) {

        self.user = message.fromFriend

    }
}


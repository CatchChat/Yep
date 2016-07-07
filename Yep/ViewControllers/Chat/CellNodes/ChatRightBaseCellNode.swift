//
//  ChatRightBaseCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

class ChatRightBaseCellNode: ChatBaseCellNode {

    override func layout() {
        super.layout()

        let x = calculatedSize.width - (ChatBaseCellNode.avatarSize.width + 15)
        let y = ChatBaseCellNode.topPadding
        let origin = CGPoint(x: x, y: y)
        avatarImageNode.frame = CGRect(origin: origin, size: ChatBaseCellNode.avatarSize)
    }
}


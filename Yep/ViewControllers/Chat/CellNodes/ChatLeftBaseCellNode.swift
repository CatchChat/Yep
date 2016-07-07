//
//  ChatLeftBaseCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

class ChatLeftBaseCellNode: ChatBaseCellNode {

    override func layout() {
        super.layout()

        let y = ChatBaseCellNode.topPadding
        avatarImageNode.frame = CGRect(origin: CGPoint(x: 15, y: y), size: ChatBaseCellNode.avatarSize)
    }
}


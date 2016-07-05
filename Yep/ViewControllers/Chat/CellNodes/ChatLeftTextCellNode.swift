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

    func configure(withMessage message: Message, layoutCache: ChatTextCellLayoutCache) {

        self.user = message.fromFriend

        do {
            let text = message.textContent
            let attributes = [
                NSForegroundColorAttributeName: UIColor.blackColor(),
                NSFontAttributeName: UIFont.systemFontOfSize(17)
            ]
            textNode.attributedText = NSAttributedString(string: text, attributes: attributes)
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let textMaxWidth = constrainedSize.width - (15 + 40 + 5 + 15)
        textNode.measure(CGSize(width: textMaxWidth, height: CGFloat.max))

        let height = max(textNode.calculatedSize.height, avatarImageNode.bounds.height)

        return CGSize(width: constrainedSize.width, height: height)
    }

    override func layout() {
        super.layout()

        textNode.frame = CGRect(x: 15 + 40 + 5, y: 0, width: textNode.calculatedSize.width, height: textNode.calculatedSize.height)
    }
}


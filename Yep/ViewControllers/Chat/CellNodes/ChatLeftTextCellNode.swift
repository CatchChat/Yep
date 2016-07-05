//
//  ChatLeftTextCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

class ChatLeftTextCellNode: ChatBaseCellNode {

    static let textAttributes = [
        NSForegroundColorAttributeName: UIColor.blackColor(),
        NSFontAttributeName: UIFont.chatTextFont(),
    ]

    lazy var textNode = ASTextNode()

    override init() {
        super.init()

        addSubnode(textNode)
        textNode.backgroundColor = UIColor.greenColor()
    }

    func configure(withMessage message: Message) {

        self.user = message.fromFriend

        do {
            let text = message.textContent
            textNode.attributedText = NSAttributedString(string: text, attributes: ChatLeftTextCellNode.textAttributes)
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let textMaxWidth = constrainedSize.width - (15 + 40 + 5 + 15)
        textNode.measure(CGSize(width: textMaxWidth, height: CGFloat.max))

        let height = max(textNode.calculatedSize.height, ChatBaseCellNode.avatarSize.height)

        return CGSize(width: constrainedSize.width, height: height)
    }

    override func layout() {
        super.layout()

        textNode.frame = CGRect(x: 15 + 40 + 5, y: 0, width: textNode.calculatedSize.width, height: textNode.calculatedSize.height)
    }
}


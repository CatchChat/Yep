//
//  ChatRightTextCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import AsyncDisplayKit

class ChatRightTextCellNode: ChatRightBaseCellNode {

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
            textNode.attributedText = NSAttributedString(string: text, attributes: ChatRightTextCellNode.textAttributes)
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let textMaxWidth = constrainedSize.width - (15 + ChatBaseCellNode.avatarSize.width + 5 + 15)
        textNode.measure(CGSize(width: textMaxWidth, height: CGFloat.max))

        let height = max(textNode.calculatedSize.height, ChatBaseCellNode.avatarSize.height)

        return CGSize(width: constrainedSize.width, height: height)
    }

    override func layout() {
        super.layout()

        let x = calculatedSize.width - (textNode.calculatedSize.width + 5 + ChatBaseCellNode.avatarSize.width + 15)
        let y: CGFloat = 0
        let origin = CGPoint(x: x, y: y)
        textNode.frame = CGRect(origin: origin, size: textNode.calculatedSize)
    }
}


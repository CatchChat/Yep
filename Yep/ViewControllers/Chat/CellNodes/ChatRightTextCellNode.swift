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
        NSForegroundColorAttributeName: UIColor.whiteColor(),
        NSFontAttributeName: UIFont.chatTextFont(),
    ]

    lazy var tailImageNode: ASImageNode = {
        let node = ASImageNode()
        node.image = UIImage(named: "bubble_right_tail")?.imageWithRenderingMode(.AlwaysOriginal)
        return node
    }()

    lazy var bubbleNode: ASDisplayNode = {
        let node = ASDisplayNode()
        node.layerBacked = true
        node.clipsToBounds = true
        node.cornerRadius = 20
        node.backgroundColor = UIColor.rightBubbleTintColor()
        return node
    }()

    lazy var textNode = ASTextNode()

    override init() {
        super.init()

        addSubnode(tailImageNode)
        addSubnode(bubbleNode)
        addSubnode(textNode)
    }

    func configure(withMessage message: Message) {

        self.user = message.fromFriend

        do {
            let text = message.textContent
            textNode.attributedText = NSAttributedString(string: text, attributes: ChatRightTextCellNode.textAttributes)
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let textMaxWidth = constrainedSize.width - ((15 + 10) + ChatBaseCellNode.avatarSize.width + (5 + 7 + 10) + 15)
        textNode.measure(CGSize(width: textMaxWidth, height: CGFloat.max))

        let height = max(textNode.calculatedSize.height + (7 + 7), ChatBaseCellNode.avatarSize.height)

        return CGSize(width: constrainedSize.width, height: height + ChatBaseCellNode.topPadding + ChatBaseCellNode.bottomPadding)
    }

    override func layout() {
        super.layout()

        let x = calculatedSize.width - (textNode.calculatedSize.width + (10 + 7 + 5) + ChatBaseCellNode.avatarSize.width + 15)
        let y = (calculatedSize.height - (ChatBaseCellNode.topPadding + ChatBaseCellNode.bottomPadding) - textNode.calculatedSize.height) / 2 + ChatBaseCellNode.topPadding
        let bubbleNodeMinWidth: CGFloat = 40
        let textNodeMinWidth = bubbleNodeMinWidth - (10 + 10)
        let offsetX = min(textNodeMinWidth, textNode.calculatedSize.width) < textNodeMinWidth ? ((textNodeMinWidth - textNode.calculatedSize.width) / 2) : 0
        let origin = CGPoint(x: x + offsetX, y: y)
        textNode.frame = CGRect(origin: origin, size: textNode.calculatedSize)

        bubbleNode.frame = CGRect(x: x - 10, y: ChatBaseCellNode.topPadding, width: max(textNodeMinWidth, textNode.calculatedSize.width) + (10 + 10), height: calculatedSize.height - (ChatBaseCellNode.topPadding + ChatBaseCellNode.bottomPadding))

        do {
            let x = calculatedSize.width - ((13 + 5) + ChatBaseCellNode.avatarSize.width + 15)
            tailImageNode.frame = CGRect(x: x, y: 20 - (14 / 2) + ChatBaseCellNode.topPadding, width: 13, height: 14)
        }
    }
}


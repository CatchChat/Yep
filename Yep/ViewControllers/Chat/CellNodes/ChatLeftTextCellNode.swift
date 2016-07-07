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

class ChatLeftTextCellNode: ChatLeftBaseCellNode {

    static let textAttributes = [
        NSForegroundColorAttributeName: UIColor.blackColor(),
        NSFontAttributeName: UIFont.chatTextFont(),
    ]

    lazy var tailImageNode: ASImageNode = {
        let node = ASImageNode()
        node.image = UIImage(named: "bubble_left_tail")?.imageWithRenderingMode(.AlwaysOriginal)
        return node
    }()

    lazy var bubbleNode: ASDisplayNode = {
        let node = ASDisplayNode()
        node.layerBacked = true
        node.clipsToBounds = true
        node.cornerRadius = 20
        node.backgroundColor = UIColor.leftBubbleTintColor()
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
            textNode.attributedText = NSAttributedString(string: text, attributes: ChatLeftTextCellNode.textAttributes)
        }
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let textMaxWidth = constrainedSize.width - (15 + ChatBaseCellNode.avatarSize.width + (5 + 7 + 10) + (10 + 15))
        textNode.measure(CGSize(width: textMaxWidth, height: CGFloat.max))

        let height = max(textNode.calculatedSize.height + (7 + 7), ChatBaseCellNode.avatarSize.height)

        return CGSize(width: constrainedSize.width, height: height + ChatBaseCellNode.verticalPadding)
    }

    override func layout() {
        super.layout()

        let x = 15 + ChatBaseCellNode.avatarSize.width + (5 + 7 + 10)
        let bubbleNodeMinWidth: CGFloat = 40
        let textNodeMinWidth = bubbleNodeMinWidth - (10 + 10)
        let offsetX = min(textNodeMinWidth, textNode.calculatedSize.width) < textNodeMinWidth ? ((textNodeMinWidth - textNode.calculatedSize.width) / 2) : 0
        let bubbleNodeHeight = calculatedSize.height - ChatBaseCellNode.verticalPadding
        let y = (bubbleNodeHeight - textNode.calculatedSize.height) / 2 + ChatBaseCellNode.topPadding
        let origin = CGPoint(x: x + offsetX, y: y)
        textNode.frame = CGRect(origin: origin, size: textNode.calculatedSize)

        bubbleNode.frame = CGRect(x: x - 10, y: ChatBaseCellNode.topPadding, width: max(textNodeMinWidth, textNode.calculatedSize.width) + (10 + 10), height: bubbleNodeHeight)

        tailImageNode.frame = CGRect(x: x - (7 + 10), y: 20 - (14 / 2) + ChatBaseCellNode.topPadding, width: 13, height: 14)
    }
}


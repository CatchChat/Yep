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

    private static let textAttributes = [
        NSForegroundColorAttributeName: UIColor.blackColor(),
        NSFontAttributeName: UIFont.chatTextFont(),
    ]

    private static let tempTextAttributes = [
        NSForegroundColorAttributeName: UIColor.redColor(),
        NSFontAttributeName: UIFont.chatTextFont(),
    ]

    private static let linkAttributes = [
        NSForegroundColorAttributeName: UIColor.yepTintColor(),
        NSFontAttributeName: UIFont.chatTextFont(),
    ]

    var tapURLAction: ((url: NSURL) -> Void)?
    var tapMentionAction: ((username: String) -> Void)?
    
    private lazy var tailImageNode: ASImageNode = {
        let node = ASImageNode()
        node.layerBacked = true
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

    lazy var textNode: ChatTextNode = {
        let node = ChatTextNode()
        node.tapURLAction = { [weak self] url in
            self?.tapURLAction?(url: url)
        }
        node.tapMentionAction = { [weak self] username in
            self?.tapMentionAction?(username: username)
        }
        return node
    }()

    override init() {
        super.init()

        addSubnode(tailImageNode)
        addSubnode(bubbleNode)
        addSubnode(textNode)
    }

    func configure(withMessage message: Message, text: String? = nil) {

        self.user = message.fromFriend

        if let text = text {
            textNode.attributedText = NSAttributedString(string: text, attributes: ChatLeftTextCellNode.tempTextAttributes)
            return
        }

        do {
            let text = message.textContent
            textNode.setText(text, withTextAttributes: ChatLeftTextCellNode.textAttributes, linkAttributes: ChatLeftTextCellNode.linkAttributes)
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


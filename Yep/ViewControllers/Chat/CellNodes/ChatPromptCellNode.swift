//
//  ChatPromptCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/6.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import AsyncDisplayKit

class ChatPromptCellNode: ASCellNode {

    private static let topPadding: CGFloat = 0
    private static let bottomPadding: CGFloat = 10
    private static var verticalPadding: CGFloat {
        return topPadding + bottomPadding
    }

    private static let textAttributes = [
        NSForegroundColorAttributeName: UIColor(white: 0.75, alpha: 1.0),
        NSFontAttributeName: UIFont.systemFontOfSize(12),
    ]

    private lazy var bubbleNode: ASDisplayNode = {
        let node = ASDisplayNode()
        node.layerBacked = true
        node.clipsToBounds = true
        node.cornerRadius = 12
        node.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        return node
    }()

    private lazy var textNode: ASTextNode = {
        let node = ASTextNode()
        node.layerBacked = true
        return node
    }()

    override init() {
        super.init()

        selectionStyle = .None
        
        addSubnode(bubbleNode)
        addSubnode(textNode)
    }

    enum PromptType {
        case RecalledMessage
        case BlockedByRecipient
    }

    func configure(withMessage message: Message, promptType: PromptType) {

        let text: String
        switch promptType {
        case .RecalledMessage:
            text = message.recalledTextContent
        case .BlockedByRecipient:
            text = message.blockedTextContent
        }

        textNode.attributedText = NSAttributedString(string: text, attributes: ChatPromptCellNode.textAttributes)
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let textMaxWidth = constrainedSize.width - (15 + 15)
        textNode.measure(CGSize(width: textMaxWidth, height: CGFloat.max))

        let height = max(24, textNode.calculatedSize.height)
        return CGSize(width: constrainedSize.width, height: height + ChatPromptCellNode.bottomPadding)
    }

    override func layout() {
        super.layout()

        let x = (calculatedSize.width - textNode.calculatedSize.width) / 2
        let bubbleNodeHeight = calculatedSize.height - ChatPromptCellNode.verticalPadding
        let y = (bubbleNodeHeight - textNode.calculatedSize.height) / 2 + ChatPromptCellNode.topPadding
        let origin = CGPoint(x: x, y: y)
        textNode.frame = CGRect(origin: origin, size: textNode.calculatedSize)

        let gap: CGFloat = 10
        bubbleNode.frame = CGRect(x: x - gap, y: ChatPromptCellNode.topPadding, width: textNode.calculatedSize.width + (gap + gap), height: bubbleNodeHeight)
    }
}


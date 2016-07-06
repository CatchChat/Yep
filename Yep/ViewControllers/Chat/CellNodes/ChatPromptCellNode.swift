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

    enum PromptType {
        case RecalledMessage
        case BlockedByRecipient
    }

    static let textAttributes = [
        NSForegroundColorAttributeName: UIColor(white: 0.75, alpha: 1.0),
        NSFontAttributeName: UIFont.systemFontOfSize(12),
    ]

    lazy var textNode: ASTextNode = {
        let node = ASTextNode()
        node.layerBacked = true
        node.clipsToBounds = true
        node.cornerRadius = 5
        node.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        return node
    }()

    override init() {
        super.init()

        addSubnode(textNode)
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

        let height = max(20, textNode.calculatedSize.height)
        return CGSize(width: constrainedSize.width, height: height)
    }

    override func layout() {
        super.layout()

        let x = (calculatedSize.width - textNode.calculatedSize.width) / 2
        let y = (calculatedSize.height - textNode.calculatedSize.height) / 2
        let origin = CGPoint(x: x, y: y)
        textNode.frame = CGRect(origin: origin, size: textNode.calculatedSize)
    }
}


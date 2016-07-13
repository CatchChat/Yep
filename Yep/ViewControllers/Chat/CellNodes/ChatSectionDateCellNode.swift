//
//  ChatSectionDateCellNode.swift
//  Yep
//
//  Created by NIX on 16/7/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import RealmSwift
import AsyncDisplayKit

class ChatSectionDateCellNode: ASCellNode {

    private static let topPadding: CGFloat = 0
    private static let bottomPadding: CGFloat = 5
    private static var verticalPadding: CGFloat {
        return topPadding + bottomPadding
    }

    private static let textAttributes = [
        NSForegroundColorAttributeName: UIColor.darkGrayColor(),
        NSFontAttributeName: UIFont.systemFontOfSize(12),
    ]

    private lazy var textNode: ASTextNode = {
        let node = ASTextNode()
        node.layerBacked = true
        return node
    }()

    override init() {
        super.init()

        selectionStyle = .None

        addSubnode(textNode)
    }

    func configure(withMessage message: Message) {

        let text = message.sectionDateString
        textNode.attributedText = NSAttributedString(string: text, attributes: ChatSectionDateCellNode.textAttributes)
    }

    func configure(withText text: String) {

        textNode.attributedText = NSAttributedString(string: text, attributes: ChatSectionDateCellNode.textAttributes)
    }

    override func calculateSizeThatFits(constrainedSize: CGSize) -> CGSize {

        let textMaxWidth = constrainedSize.width - (15 + 15)
        textNode.measure(CGSize(width: textMaxWidth, height: CGFloat.max))

        let height = max(20, textNode.calculatedSize.height)
        return CGSize(width: constrainedSize.width, height: height + ChatSectionDateCellNode.verticalPadding)
    }

    override func layout() {
        super.layout()

        let x = (calculatedSize.width - textNode.calculatedSize.width) / 2
        let containerHeight = calculatedSize.height - ChatSectionDateCellNode.verticalPadding
        let y = (containerHeight - textNode.calculatedSize.height) / 2 + ChatSectionDateCellNode.topPadding
        let origin = CGPoint(x: x, y: y)
        textNode.frame = CGRect(origin: origin, size: textNode.calculatedSize)
    }
}


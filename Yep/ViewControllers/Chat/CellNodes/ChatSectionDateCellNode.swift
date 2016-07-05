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

    lazy var textNode: ASTextNode = {
        let node = ASTextNode()
        node.layerBacked = true
        return node
    }()

    override init() {
        super.init()

        addSubnode(textNode)
    }

    func configure(withMessage message: Message) {

        let text = message.sectionDateString
        let attributes = [
            NSForegroundColorAttributeName: UIColor.darkGrayColor(),
            NSFontAttributeName: UIFont.systemFontOfSize(12),
        ]
        textNode.attributedText = NSAttributedString(string: text, attributes: attributes)
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


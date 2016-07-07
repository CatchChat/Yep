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

class LeftBubbleNode: ASDisplayNode {

    override class func drawRect(bounds: CGRect, withParameters parameters: NSObjectProtocol!, isCancelled isCancelledBlock: asdisplaynode_iscancelled_block_t, isRasterizing: Bool) {

        let context = UIGraphicsGetCurrentContext()
        CGContextSaveGState(context)

        UIColor.leftBubbleTintColor().setFill()

        do {
            let path = UIBezierPath()
            let arrowPoint = CGPoint(x: 0, y: 20)
            let topPoint = CGPoint(x: 11, y: 10)
            let topControlPoint = CGPoint(x: 7, y: 20)
            let bottomPoint = CGPoint(x: 11, y: 30)
            let bottomControlPoint = CGPoint(x: 7, y: 20)
            path.moveToPoint(arrowPoint)
            path.addQuadCurveToPoint(topPoint, controlPoint: topControlPoint)
            path.addLineToPoint(bottomPoint)
            path.addQuadCurveToPoint(arrowPoint, controlPoint: bottomControlPoint)
            path.fill()
        }

        do {
            let rect = CGRect(x: 8, y: 0, width: bounds.width - 8, height: bounds.height)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 15)
            path.fill()
        }

        CGContextRestoreGState(context)
    }
}

class ChatLeftTextCellNode: ChatLeftBaseCellNode {

    static let textAttributes = [
        NSForegroundColorAttributeName: UIColor.blackColor(),
        NSFontAttributeName: UIFont.chatTextFont(),
    ]

    lazy var bubbleNode: LeftBubbleNode = {
        let node = LeftBubbleNode()
        return node
    }()

    lazy var textNode = ASTextNode()

    override init() {
        super.init()

        addSubnode(bubbleNode)
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

        let textMaxWidth = constrainedSize.width - (15 + ChatBaseCellNode.avatarSize.width + (5 + 8 + 10) + 15)
        textNode.measure(CGSize(width: textMaxWidth, height: CGFloat.max))

        let height = max(textNode.calculatedSize.height + (10 + 10), ChatBaseCellNode.avatarSize.height)

        return CGSize(width: constrainedSize.width, height: height)
    }

    override func layout() {
        super.layout()

        let x = 15 + ChatBaseCellNode.avatarSize.width + (5 + 8 + 10)
        let y = (calculatedSize.height - textNode.calculatedSize.height) / 2
        let origin = CGPoint(x: x, y: y)
        textNode.frame = CGRect(origin: origin, size: textNode.calculatedSize)

        bubbleNode.frame = CGRect(x: x - (8 + 10), y: 0, width: textNode.calculatedSize.width + ((8 + 10) + 10), height: calculatedSize.height)
    }
}


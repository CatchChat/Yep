//
//  BorderTextField.swift
//  Yep
//
//  Created by NIX on 15/6/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class BorderTextField: UITextField {

    @IBInspectable var lineColor: UIColor = UIColor.yepBorderColor()
    @IBInspectable var lineWidth: CGFloat = 1 / UIScreen.mainScreen().scale

    @IBInspectable var enabledTopLine: Bool = true
    @IBInspectable var enabledLeftLine: Bool = false
    @IBInspectable var enabledBottomLine: Bool = true
    @IBInspectable var enabledRightLine: Bool = false

    @IBInspectable var leftTextInset: CGFloat = 20
    @IBInspectable var rightTextInset: CGFloat = 20

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        lineColor.setStroke()

        let context = UIGraphicsGetCurrentContext()

        CGContextSetLineWidth(context, lineWidth)

        if enabledTopLine {
            CGContextMoveToPoint(context, 0, 0)
            CGContextAddLineToPoint(context, CGRectGetWidth(rect), 0)
            CGContextStrokePath(context)
        }

        if enabledLeftLine {
            let y = CGRectGetHeight(rect)
            CGContextMoveToPoint(context, 0, 0)
            CGContextAddLineToPoint(context, 0, y)
            CGContextStrokePath(context)
        }

        if enabledBottomLine {
            let y = CGRectGetHeight(rect)
            CGContextMoveToPoint(context, 0, y)
            CGContextAddLineToPoint(context, CGRectGetWidth(rect), y)
            CGContextStrokePath(context)
        }

        if enabledRightLine {
            let x = CGRectGetWidth(rect)
            let y = CGRectGetHeight(rect)
            CGContextMoveToPoint(context, x, 0)
            CGContextAddLineToPoint(context, x, y)
            CGContextStrokePath(context)
        }
    }

    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRect(x: leftTextInset, y: 0, width: bounds.width - leftTextInset - rightTextInset, height: bounds.height)
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return textRectForBounds(bounds)
    }
}

//
//  BorderTextField.swift
//  
//
//  Created by NIX on 15/6/15.
//
//

import UIKit

@IBDesignable
class BorderTextField: UITextField {

    @IBInspectable var lineColor: UIColor = UIColor.lightGrayColor()
    @IBInspectable var lineWidth: CGFloat = 1 / UIScreen.mainScreen().scale
    @IBInspectable var horizontalInset: CGFloat = 20

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        lineColor.setStroke()

        let context = UIGraphicsGetCurrentContext()

        CGContextSetLineWidth(context, lineWidth)

        CGContextMoveToPoint(context, 0, 0)
        CGContextAddLineToPoint(context, CGRectGetWidth(rect), 0)
        CGContextStrokePath(context)

        let y = CGRectGetHeight(rect)
        CGContextMoveToPoint(context, 0, y)
        CGContextAddLineToPoint(context, CGRectGetWidth(rect), y)
        CGContextStrokePath(context)
    }

    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRectInset(bounds, horizontalInset, 0)
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return textRectForBounds(bounds)
    }
}

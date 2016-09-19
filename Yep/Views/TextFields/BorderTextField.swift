//
//  BorderTextField.swift
//  Yep
//
//  Created by NIX on 15/6/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
final class BorderTextField: UITextField {

    @IBInspectable var lineColor: UIColor = UIColor.yepBorderColor()
    @IBInspectable var lineWidth: CGFloat = 1 / UIScreen.main.scale

    @IBInspectable var enabledTopLine: Bool = true
    @IBInspectable var enabledLeftLine: Bool = false
    @IBInspectable var enabledBottomLine: Bool = true
    @IBInspectable var enabledRightLine: Bool = false

    @IBInspectable var leftTextInset: CGFloat = 20
    @IBInspectable var rightTextInset: CGFloat = 20

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        lineColor.setStroke()

        let context = UIGraphicsGetCurrentContext()

        context!.setLineWidth(lineWidth)

        if enabledTopLine {
            context!.move(to: CGPoint(x: 0, y: 0))
            context!.addLine(to: CGPoint(x: rect.width, y: 0))
            context!.strokePath()
        }

        if enabledLeftLine {
            let y = rect.height
            context!.move(to: CGPoint(x: 0, y: 0))
            context!.addLine(to: CGPoint(x: 0, y: y))
            context!.strokePath()
        }

        if enabledBottomLine {
            let y = rect.height
            context!.move(to: CGPoint(x: 0, y: y))
            context!.addLine(to: CGPoint(x: rect.width, y: y))
            context!.strokePath()
        }

        if enabledRightLine {
            let x = rect.width
            let y = rect.height
            context!.move(to: CGPoint(x: x, y: 0))
            context!.addLine(to: CGPoint(x: x, y: y))
            context!.strokePath()
        }
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: leftTextInset, y: 0, width: bounds.width - leftTextInset - rightTextInset, height: bounds.height)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}

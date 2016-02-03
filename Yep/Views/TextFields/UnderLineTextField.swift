//
//  UnderLineTextField.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class UnderLineTextField: UITextField {

    @IBInspectable var underLineColor: UIColor = UIColor.yepTintColor()
    @IBInspectable var underLineWidth: CGFloat = 1
    @IBInspectable var leftInset: CGFloat = 0
    @IBInspectable var rightInset: CGFloat = 0

    lazy var underlineLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = self.underLineWidth
        layer.strokeColor = self.underLineColor.CGColor
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clearColor()

        layer.addSublayer(underlineLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath()
        path.moveToPoint(CGPoint(x: 0, y: CGRectGetHeight(bounds)))
        path.addLineToPoint(CGPoint(x: CGRectGetWidth(bounds), y: CGRectGetHeight(bounds)))

        underlineLayer.path = path.CGPath
    }

    override func textRectForBounds(bounds: CGRect) -> CGRect {
        return CGRect(x: leftInset, y: 0, width: bounds.width - (leftInset + rightInset), height: bounds.height)
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        return textRectForBounds(bounds)
    }
}


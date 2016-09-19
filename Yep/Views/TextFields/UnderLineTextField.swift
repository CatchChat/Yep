//
//  UnderLineTextField.swift
//  Yep
//
//  Created by NIX on 15/3/17.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
final class UnderLineTextField: UITextField {

    @IBInspectable var underLineColor: UIColor = UIColor.yepTintColor()
    @IBInspectable var underLineWidth: CGFloat = 1
    @IBInspectable var leftInset: CGFloat = 0
    @IBInspectable var rightInset: CGFloat = 0

    lazy var underlineLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.lineWidth = self.underLineWidth
        layer.strokeColor = self.underLineColor.cgColor
        return layer
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clear

        layer.addSublayer(underlineLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.height))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.height))

        underlineLayer.path = path.cgPath
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: leftInset, y: 0, width: bounds.width - (leftInset + rightInset), height: bounds.height)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textRect(forBounds: bounds)
    }
}


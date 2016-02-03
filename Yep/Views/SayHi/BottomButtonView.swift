//
//  SayHiView.swift
//  Yep
//
//  Created by NIX on 15/5/29.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
class BottomButtonView: UIView {

    @IBInspectable var topLineColor: UIColor = UIColor.yepBorderColor()
    @IBInspectable var topLineWidth: CGFloat = 1 / UIScreen.mainScreen().scale
    @IBInspectable var title: String = NSLocalizedString("Say Hi", comment: "") {
        didSet {
            actionButton.setTitle(title, forState: .Normal)
        }
    }

    lazy var actionButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFontOfSize(14)
        button.setTitle(self.title, forState: .Normal)
        button.backgroundColor = UIColor.yepTintColor()
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: "tryTap", forControlEvents: UIControlEvents.TouchUpInside)
        return button
    }()

    var tapAction: (() -> Void)?

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.whiteColor()

        // Add actionButton

        self.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        let actionButtonCenterXConstraint = NSLayoutConstraint(item: actionButton, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1.0, constant: 0)

        let actionButtonCenterYConstraint = NSLayoutConstraint(item: actionButton, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1.0, constant: 0)

        let actionButtonWidthConstraint = NSLayoutConstraint(item: actionButton, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 185)

        let actionButtonHeightConstraint = NSLayoutConstraint(item: actionButton, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 30)

        let constraints = [
            actionButtonCenterXConstraint,
            actionButtonCenterYConstraint,
            actionButtonWidthConstraint,
            actionButtonHeightConstraint,
        ]

        NSLayoutConstraint.activateConstraints(constraints)
    }

    // MARK: Actions

    func tryTap() {
        tapAction?()
    }

    // MARK: Draw

    override func drawRect(rect: CGRect) {
        super.drawRect(rect)

        topLineColor.setStroke()

        let context = UIGraphicsGetCurrentContext()

        CGContextSetLineWidth(context, topLineWidth)
        CGContextMoveToPoint(context, 0, 0)
        CGContextAddLineToPoint(context, CGRectGetWidth(rect), 0)
        CGContextStrokePath(context)
    }
}


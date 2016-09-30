//
//  SayHiView.swift
//  Yep
//
//  Created by NIX on 15/5/29.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

@IBDesignable
final class BottomButtonView: UIView {

    @IBInspectable var topLineColor: UIColor = UIColor.yepBorderColor()
    @IBInspectable var topLineWidth: CGFloat = 1 / UIScreen.main.scale
    @IBInspectable var title: String = NSLocalizedString("Say Hi", comment: "") {
        didSet {
            actionButton.setTitle(title, for: .normal)
        }
    }

    lazy var actionButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(self.title, for: .normal)
        button.backgroundColor = UIColor.yepTintColor()
        button.setTitleColor(UIColor.white, for: .normal)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(BottomButtonView.tryTap), for: UIControlEvents.touchUpInside)
        return button
    }()

    var tapAction: (() -> Void)?

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.white

        // Add actionButton

        self.addSubview(actionButton)
        actionButton.translatesAutoresizingMaskIntoConstraints = false

        let actionButtonCenterXConstraint = NSLayoutConstraint(item: actionButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0)

        let actionButtonCenterYConstraint = NSLayoutConstraint(item: actionButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: 0)

        let actionButtonWidthConstraint = NSLayoutConstraint(item: actionButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 185)

        let actionButtonHeightConstraint = NSLayoutConstraint(item: actionButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30)

        let constraints: [NSLayoutConstraint] = [
            actionButtonCenterXConstraint,
            actionButtonCenterYConstraint,
            actionButtonWidthConstraint,
            actionButtonHeightConstraint,
        ]

        NSLayoutConstraint.activate(constraints)
    }

    // MARK: Actions

    func tryTap() {
        tapAction?()
    }

    // MARK: Draw

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        topLineColor.setStroke()

        let context = UIGraphicsGetCurrentContext()

        context!.setLineWidth(topLineWidth)
        context!.move(to: CGPoint(x: 0, y: 0))
        context!.addLine(to: CGPoint(x: rect.width, y: 0))
        context!.strokePath()
    }
}


//
//  SubscribeView.swift
//  Yep
//
//  Created by nixzhu on 15/12/1.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SubscribeView: UIView {

    static let height: CGFloat = 44

    var bottomConstraint: NSLayoutConstraint?

    lazy var subscribeButton: BorderButton = {
        let button = BorderButton()
        return button
    }()

    lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.redColor()
        return button
    }()

    override func didMoveToSuperview() {

        makeUI()
    }

    func makeUI() {

        backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.3)

        addSubview(subscribeButton)
        addSubview(dismissButton)

        subscribeButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "subscribeButton": subscribeButton,
            "dismissButton": dismissButton,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:[subscribeButton][dismissButton]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views)

        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[dismissButton]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
    }

    func show() {

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = 0
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })
    }

    func hide() {

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = -SubscribeView.height
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })
    }
}


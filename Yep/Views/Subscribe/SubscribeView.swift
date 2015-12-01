//
//  SubscribeView.swift
//  Yep
//
//  Created by nixzhu on 15/12/1.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SubscribeView: UIView {

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

    }
}


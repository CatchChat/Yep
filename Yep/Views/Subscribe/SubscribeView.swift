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

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_chat_active_unread")
        return imageView
    }()

    lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(14)
        label.text = NSLocalizedString("Get notified.", comment: "")
        label.textColor = UIColor.darkGrayColor()
        return label
    }()

    lazy var subscribeButton: BorderButton = {
        let button = BorderButton()
        button.titleLabel?.font = UIFont.systemFontOfSize(14)
        button.setTitle(NSLocalizedString("Subscribe", comment: ""), forState: .Normal)
        button.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        return button
    }()

    lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_current_location"), forState: .Normal)
        return button
    }()

    override func didMoveToSuperview() {

        makeUI()
    }

    func makeUI() {

        backgroundColor = UIColor.whiteColor()

        addSubview(iconImageView)
        addSubview(promptLabel)
        addSubview(subscribeButton)
        addSubview(dismissButton)

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        subscribeButton.translatesAutoresizingMaskIntoConstraints = false
        dismissButton.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "iconImageView": iconImageView,
            "promptLabel": promptLabel,
            "subscribeButton": subscribeButton,
            "dismissButton": dismissButton,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[iconImageView]-[promptLabel]-(>=10)-[subscribeButton]-[dismissButton]-|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views)

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


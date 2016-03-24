//
//  SubscribeView.swift
//  Yep
//
//  Created by nixzhu on 15/12/1.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SubscribeView: UIView {

    static let height: CGFloat = 50

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "icon_subscribe_notify")
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
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)

        button.addTarget(self, action: "subscribe:", forControlEvents: .TouchUpInside)

        return button
    }()

    lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "icon_subscribe_close"), forState: .Normal)

        button.addTarget(self, action: "dismiss:", forControlEvents: .TouchUpInside)

        return button
    }()

    var subscribeAction: (() -> Void)?
    var showWithChangeAction: (() -> Void)?
    var hideWithChangeAction: (() -> Void)?

    override func didMoveToSuperview() {

        makeUI()
    }

    func makeUI() {

        backgroundColor = UIColor.whiteColor()

        do {
            let horizontalLineView = HorizontalLineView()
            addSubview(horizontalLineView)
            horizontalLineView.translatesAutoresizingMaskIntoConstraints = false

            horizontalLineView.backgroundColor = UIColor.clearColor()
            horizontalLineView.atBottom = false

            let views = [
                "horizontalLineView": horizontalLineView,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[horizontalLineView]|", options: [], metrics: nil, views: views)

            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[horizontalLineView(1)]", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

        do {
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

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-[iconImageView]-[promptLabel]-(>=10)-[subscribeButton]-[dismissButton]-(9)-|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views)

            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[dismissButton]|", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }
    }

    weak var bottomConstraint: NSLayoutConstraint?

    func show() {

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = 0
            self?.showWithChangeAction?()
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })
    }

    func hide() {

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = SubscribeView.height
            self?.hideWithChangeAction?()
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })
    }

    func subscribe(sender: BorderButton) {

        subscribeAction?()

        hide()
    }

    func dismiss(sender: UIButton) {

        hide()
    }
}


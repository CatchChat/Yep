//
//  SubscribeView.swift
//  Yep
//
//  Created by nixzhu on 15/12/1.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class SubscribeView: UIView {

    static let height: CGFloat = 50

    var subscribeAction: (() -> Void)?
    var showWithChangeAction: (() -> Void)?
    var hideWithChangeAction: (() -> Void)?

    private lazy var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_iconSubscribeNotify
        return imageView
    }()

    private lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(14)
        label.text = NSLocalizedString("Get notified.", comment: "")
        label.textColor = UIColor.darkGrayColor()
        return label
    }()

    private lazy var subscribeButton: BorderButton = {
        let button = BorderButton()
        button.titleLabel?.font = UIFont.systemFontOfSize(14)
        button.setTitle(NSLocalizedString("Subscribe", comment: ""), forState: .Normal)
        button.setTitleColor(UIColor.yepTintColor(), forState: .Normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)

        button.addTarget(self, action: #selector(SubscribeView.subscribe(_:)), forControlEvents: .TouchUpInside)

        return button
    }()

    private lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.yep_iconSubscribeClose, forState: .Normal)

        button.addTarget(self, action: #selector(SubscribeView.dismiss(_:)), forControlEvents: .TouchUpInside)

        return button
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {

        backgroundColor = UIColor.whiteColor()

        do {
            addSubview(blurView)
            blurView.translatesAutoresizingMaskIntoConstraints = false
            blurView.leadingAnchor.constraintEqualToAnchor(leadingAnchor).active = true
            blurView.trailingAnchor.constraintEqualToAnchor(trailingAnchor).active = true
            blurView.topAnchor.constraintEqualToAnchor(topAnchor).active = true
            blurView.bottomAnchor.constraintEqualToAnchor(bottomAnchor).active = true
        }

        do {
            let horizontalLineView = HorizontalLineView()
            addSubview(horizontalLineView)
            horizontalLineView.translatesAutoresizingMaskIntoConstraints = false

            horizontalLineView.backgroundColor = UIColor.clearColor()
            horizontalLineView.atBottom = false

            let views: [String: AnyObject] = [
                "horizontalLineView": horizontalLineView,
            ]

            let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[horizontalLineView]|", options: [], metrics: nil, views: views)

            let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[horizontalLineView(1)]", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activateConstraints(constraintsH)
            NSLayoutConstraint.activateConstraints(constraintsV)
        }

        do {
            blurView.contentView.addSubview(iconImageView)
            blurView.contentView.addSubview(promptLabel)
            blurView.contentView.addSubview(subscribeButton)
            blurView.contentView.addSubview(dismissButton)

            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            promptLabel.translatesAutoresizingMaskIntoConstraints = false
            subscribeButton.translatesAutoresizingMaskIntoConstraints = false
            dismissButton.translatesAutoresizingMaskIntoConstraints = false

            let views: [String: AnyObject] = [
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

    @objc private func subscribe(sender: BorderButton) {

        subscribeAction?()

        hide()
    }

    @objc private func dismiss(sender: UIButton) {

        hide()
    }
}


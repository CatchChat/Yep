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

    fileprivate lazy var blurView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))

    fileprivate lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage.yep_iconSubscribeNotify
        return imageView
    }()

    fileprivate lazy var promptLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = String.trans_promptGetNotifiedWithSubscribe
        label.textColor = UIColor.darkGray
        return label
    }()

    fileprivate lazy var subscribeButton: BorderButton = {
        let button = BorderButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setTitle(NSLocalizedString("Subscribe", comment: ""), for: UIControlState())
        button.setTitleColor(UIColor.yepTintColor(), for: UIControlState())
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)

        button.addTarget(self, action: #selector(SubscribeView.subscribe(_:)), for: .touchUpInside)

        return button
    }()

    fileprivate lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage.yep_iconSubscribeClose, for: UIControlState())

        button.addTarget(self, action: #selector(SubscribeView.dismiss(_:)), for: .touchUpInside)

        return button
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {

        backgroundColor = UIColor.white

        do {
            addSubview(blurView)
            blurView.translatesAutoresizingMaskIntoConstraints = false
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            blurView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }

        do {
            let horizontalLineView = HorizontalLineView()
            addSubview(horizontalLineView)
            horizontalLineView.translatesAutoresizingMaskIntoConstraints = false

            horizontalLineView.backgroundColor = UIColor.clear
            horizontalLineView.atBottom = false

            let views: [String: Any] = [
                "horizontalLineView": horizontalLineView,
            ]

            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[horizontalLineView]|", options: [], metrics: nil, views: views)

            let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[horizontalLineView(1)]", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate(constraintsV)
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

            let views: [String: Any] = [
                "iconImageView": iconImageView,
                "promptLabel": promptLabel,
                "subscribeButton": subscribeButton,
                "dismissButton": dismissButton,
            ]

            let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[iconImageView]-[promptLabel]-(>=10)-[subscribeButton]-[dismissButton]-(9)-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: views)

            let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[dismissButton]|", options: [], metrics: nil, views: views)

            NSLayoutConstraint.activate(constraintsH)
            NSLayoutConstraint.activate(constraintsV)
        }
    }

    weak var bottomConstraint: NSLayoutConstraint?

    func show() {

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = 0
            self?.showWithChangeAction?()
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })
    }

    func hide() {

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = SubscribeView.height
            self?.hideWithChangeAction?()
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })
    }

    @objc fileprivate func subscribe(_ sender: BorderButton) {

        subscribeAction?()

        hide()
    }

    @objc fileprivate func dismiss(_ sender: UIButton) {

        hide()
    }
}


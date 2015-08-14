//
//  FriendRequestView.swift
//  Yep
//
//  Created by nixzhu on 15/8/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FriendRequestView: UIView {

    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
        }()

    lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(16)
        label.text = "NIX"
        label.textColor = UIColor.blackColor().colorWithAlphaComponent(0.9)
        return label
        }()

    lazy var stateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFontOfSize(14)
        label.text = "is not your friend, yet"
        label.textColor = UIColor.grayColor().colorWithAlphaComponent(0.9)
        return label
        }()

    lazy var actionButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("Add", comment: ""), forState: .Normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.backgroundColor = UIColor.yepTintColor()
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
        button.layer.cornerRadius = 5
        return button
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        backgroundColor = UIColor.clearColor()
        
        avatarImageView.backgroundColor = UIColor.redColor()
    }

    class ContainerView: UIView {

        override func didMoveToSuperview() {
            super.didMoveToSuperview()

            backgroundColor = UIColor.clearColor()
        }

        override func drawRect(rect: CGRect) {
            super.drawRect(rect)

            let context = UIGraphicsGetCurrentContext()

            let y = CGRectGetHeight(rect)
            CGContextMoveToPoint(context, 0, y)
            CGContextAddLineToPoint(context, CGRectGetWidth(rect), y)

            let bottomLineWidth: CGFloat = 1 / UIScreen.mainScreen().scale
            CGContextSetLineWidth(context, bottomLineWidth)

            UIColor.lightGrayColor().setStroke()
            
            CGContextStrokePath(context)
        }
    }

    func makeUI() {

        let blurEffect = UIBlurEffect(style: .ExtraLight)
        let visualEffectView = UIVisualEffectView(effect: blurEffect)

        visualEffectView.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(visualEffectView)

        let containerView = ContainerView()
        containerView.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(containerView)

        avatarImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        containerView.addSubview(avatarImageView)

        nicknameLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        containerView.addSubview(nicknameLabel)

        stateLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        containerView.addSubview(stateLabel)

        actionButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        containerView.addSubview(actionButton)

        let viewsDictionary = [
            "visualEffectView": visualEffectView,
            "containerView": containerView,
        ]

        // visualEffectView

        let visualEffectViewConstraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[visualEffectView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)
        let visualEffectViewConstraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[visualEffectView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(visualEffectViewConstraintH)
        NSLayoutConstraint.activateConstraints(visualEffectViewConstraintV)

        // containerView

        let containerViewConstraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)
        let containerViewConstraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: NSLayoutFormatOptions(0), metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(containerViewConstraintH)
        NSLayoutConstraint.activateConstraints(containerViewConstraintV)

        // avatarImageView

        let avatarImageViewCenterY = NSLayoutConstraint(item: avatarImageView, attribute: .CenterY, relatedBy: .Equal, toItem: containerView, attribute: .CenterY, multiplier: 1, constant: 0)
        let avatarImageViewLeading = NSLayoutConstraint(item: avatarImageView, attribute: .Leading, relatedBy: .Equal, toItem: containerView, attribute: .Leading, multiplier: 1, constant: YepConfig.chatCellGapBetweenWallAndAvatar())
        let avatarImageViewWidth = NSLayoutConstraint(item: avatarImageView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: YepConfig.chatCellAvatarSize())
        let avatarImageViewHeight = NSLayoutConstraint(item: avatarImageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: YepConfig.chatCellAvatarSize())

        NSLayoutConstraint.activateConstraints([avatarImageViewCenterY, avatarImageViewLeading, avatarImageViewWidth, avatarImageViewHeight])

        // nicknameLabel

        let nicknameLabelTop = NSLayoutConstraint(item: nicknameLabel, attribute: .Top, relatedBy: .Equal, toItem: avatarImageView, attribute: .Top, multiplier: 1, constant: 0)
        let nicknameLabelLeft = NSLayoutConstraint(item: nicknameLabel, attribute: .Left, relatedBy: .Equal, toItem: avatarImageView, attribute: .Right, multiplier: 1, constant: 15)

        NSLayoutConstraint.activateConstraints([nicknameLabelTop, nicknameLabelLeft])

        // stateLabel

        let stateLabelBottom = NSLayoutConstraint(item: stateLabel, attribute: .Bottom, relatedBy: .Equal, toItem: avatarImageView, attribute: .Bottom, multiplier: 1, constant: 0)
        let stateLabelLeft = NSLayoutConstraint(item: stateLabel, attribute: .Left, relatedBy: .Equal, toItem: nicknameLabel, attribute: .Left, multiplier: 1, constant: 0)

        NSLayoutConstraint.activateConstraints([stateLabelBottom, stateLabelLeft])

        // actionButton

        let actionButtonTrailing = NSLayoutConstraint(item: actionButton, attribute: .Trailing, relatedBy: .Equal, toItem: containerView, attribute: .Trailing, multiplier: 1, constant: -YepConfig.chatCellGapBetweenWallAndAvatar())
        let actionButtonCenterY = NSLayoutConstraint(item: actionButton, attribute: .CenterY, relatedBy: .Equal, toItem: containerView, attribute: .CenterY, multiplier: 1, constant: 0)

        NSLayoutConstraint.activateConstraints([actionButtonTrailing, actionButtonCenterY])
    }
}


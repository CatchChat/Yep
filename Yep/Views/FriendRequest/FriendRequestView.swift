//
//  FriendRequestView.swift
//  Yep
//
//  Created by nixzhu on 15/8/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FriendRequestView: UIView {

    static let height: CGFloat = 60

    enum State {
        case Add(prompt: String)
        case Consider(prompt: String, friendRequestID: String)

        var prompt: String {
            switch self {
            case .Add(let prompt):
                return prompt
            case .Consider(let prompt, _):
                return prompt
            }
        }

        var friendRequestID: String? {
            switch self {
            case .Consider( _, let friendRequestID):
                return friendRequestID
            default:
                return nil
            }
        }
    }
    let state: State

    init(state: State) {
        self.state = state

        super.init(frame: CGRectZero)

        self.stateLabel.text = state.prompt
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var user: User? {
        willSet {
            if let user = newValue {
                let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: nanoAvatarStyle)
                avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

                nicknameLabel.text = user.nickname
            }
        }
    }

    var addAction: (FriendRequestView -> Void)?
    var acceptAction: (FriendRequestView -> Void)?
    var rejectAction: (FriendRequestView -> Void)?

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
        label.numberOfLines = 0
        label.textColor = UIColor.grayColor().colorWithAlphaComponent(0.9)
        return label
    }()

    func baseButton() -> UIButton {
        let button = UIButton()
        button.setContentHuggingPriority(300, forAxis: UILayoutConstraintAxis.Horizontal)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        button.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        button.setTitleColor(UIColor.grayColor(), forState: .Highlighted)
        button.setTitleColor(UIColor.lightGrayColor(), forState: .Disabled)
        button.layer.cornerRadius = 5
        return button
    }

    lazy var addButton: UIButton = {
        let button = self.baseButton()
        button.setTitle(NSLocalizedString("Add", comment: ""), forState: .Normal)
        button.backgroundColor = UIColor.yepTintColor()
        button.addTarget(self, action: "tryAddAction", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var acceptButton: UIButton = {
        let button = self.baseButton()
        button.setTitle(NSLocalizedString("Accept", comment: ""), forState: .Normal)
        button.backgroundColor = UIColor.yepTintColor()
        button.addTarget(self, action: "tryAcceptAction", forControlEvents: .TouchUpInside)
        return button
    }()

    lazy var rejectButton: UIButton = {
        let button = self.baseButton()
        button.setTitle(NSLocalizedString("Reject", comment: ""), forState: .Normal)
        button.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)
        button.setTitleColor(UIColor.darkGrayColor(), forState: UIControlState.Normal)
        button.addTarget(self, action: "tryRejectAction", forControlEvents: .TouchUpInside)
        return button
    }()

    // MARK: Actions

    func tryAddAction() {
        addAction?(self)
    }

    func tryAcceptAction() {
        acceptAction?(self)
    }

    func tryRejectAction() {
        rejectAction?(self)
    }

    // MARK: UI

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        backgroundColor = UIColor.clearColor()

        makeUI()
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

        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffectView)

        let containerView = ContainerView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(avatarImageView)

        nicknameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nicknameLabel)

        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(stateLabel)

        let viewsDictionary = [
            "visualEffectView": visualEffectView,
            "containerView": containerView,
        ]

        // visualEffectView

        let visualEffectViewConstraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[visualEffectView]|", options: [], metrics: nil, views: viewsDictionary)
        let visualEffectViewConstraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[visualEffectView]|", options: [], metrics: nil, views: viewsDictionary)

        NSLayoutConstraint.activateConstraints(visualEffectViewConstraintH)
        NSLayoutConstraint.activateConstraints(visualEffectViewConstraintV)

        // containerView

        let containerViewConstraintH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[containerView]|", options: [], metrics: nil, views: viewsDictionary)
        let containerViewConstraintV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[containerView]|", options: [], metrics: nil, views: viewsDictionary)

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
        let nicknameLabelLeft = NSLayoutConstraint(item: nicknameLabel, attribute: .Left, relatedBy: .Equal, toItem: avatarImageView, attribute: .Right, multiplier: 1, constant: 8)

        NSLayoutConstraint.activateConstraints([nicknameLabelTop, nicknameLabelLeft])

        // stateLabel

        let stateLabelTop = NSLayoutConstraint(item: stateLabel, attribute: .Top, relatedBy: .Equal, toItem: nicknameLabel, attribute: .Bottom, multiplier: 1, constant: 0)
        let stateLabelBottom = NSLayoutConstraint(item: stateLabel, attribute: .Bottom, relatedBy: .LessThanOrEqual, toItem: containerView, attribute: .Bottom, multiplier: 1, constant: -4)
        let stateLabelLeft = NSLayoutConstraint(item: stateLabel, attribute: .Left, relatedBy: .Equal, toItem: nicknameLabel, attribute: .Left, multiplier: 1, constant: 0)

        NSLayoutConstraint.activateConstraints([stateLabelTop, stateLabelBottom, stateLabelLeft])

        switch state {

        case .Add:

            // addButton

            addButton.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(addButton)

            let addButtonTrailing = NSLayoutConstraint(item: addButton, attribute: .Trailing, relatedBy: .Equal, toItem: containerView, attribute: .Trailing, multiplier: 1, constant: -YepConfig.chatCellGapBetweenWallAndAvatar())
            let addButtonCenterY = NSLayoutConstraint(item: addButton, attribute: .CenterY, relatedBy: .Equal, toItem: containerView, attribute: .CenterY, multiplier: 1, constant: 0)

            NSLayoutConstraint.activateConstraints([addButtonTrailing, addButtonCenterY])

            // labels' right

            let nicknameLabelRight = NSLayoutConstraint(item: nicknameLabel, attribute: .Right, relatedBy: .Equal, toItem: addButton, attribute: .Left, multiplier: 1, constant: -8)
            let stateLabelRight = NSLayoutConstraint(item: stateLabel, attribute: .Right, relatedBy: .Equal, toItem: addButton, attribute: .Left, multiplier: 1, constant: -8)

            NSLayoutConstraint.activateConstraints([nicknameLabelRight, stateLabelRight])

        case .Consider:

            // acceptButton

            acceptButton.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(acceptButton)

            let acceptButtonTrailing = NSLayoutConstraint(item: acceptButton, attribute: .Trailing, relatedBy: .Equal, toItem: containerView, attribute: .Trailing, multiplier: 1, constant: -YepConfig.chatCellGapBetweenWallAndAvatar())
            let acceptButtonCenterY = NSLayoutConstraint(item: acceptButton, attribute: .CenterY, relatedBy: .Equal, toItem: containerView, attribute: .CenterY, multiplier: 1, constant: 0)

            NSLayoutConstraint.activateConstraints([acceptButtonTrailing, acceptButtonCenterY])

            // rejectButton

            rejectButton.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(rejectButton)

            let rejectButtonRight = NSLayoutConstraint(item: rejectButton, attribute: .Right, relatedBy: .Equal, toItem: acceptButton, attribute: .Left, multiplier: 1, constant: -8)
            let rejectButtonCenterY = NSLayoutConstraint(item: rejectButton, attribute: .CenterY, relatedBy: .Equal, toItem: containerView, attribute: .CenterY, multiplier: 1, constant: 0)

            NSLayoutConstraint.activateConstraints([rejectButtonRight, rejectButtonCenterY])

            // labels' right

            let nicknameLabelRight = NSLayoutConstraint(item: nicknameLabel, attribute: .Right, relatedBy: .Equal, toItem: rejectButton, attribute: .Left, multiplier: 1, constant: -8)
            let stateLabelRight = NSLayoutConstraint(item: stateLabel, attribute: .Right, relatedBy: .Equal, toItem: rejectButton, attribute: .Left, multiplier: 1, constant: -8)

            NSLayoutConstraint.activateConstraints([nicknameLabelRight, stateLabelRight])
        }
    }
}


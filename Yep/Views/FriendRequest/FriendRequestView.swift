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
        label.text = "Love"
        return label
        }()

    lazy var stateLabel: UILabel = {
        let label = UILabel()
        return label
        }()

    lazy var actionButton: UIButton = {
        let button = UIButton()
        return button
        }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()

        backgroundColor = UIColor.lightGrayColor()
        
        avatarImageView.backgroundColor = UIColor.redColor()
    }

    func makeUI() {

        avatarImageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(avatarImageView)

        nicknameLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(nicknameLabel)

        stateLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(stateLabel)

        actionButton.setTranslatesAutoresizingMaskIntoConstraints(false)
        addSubview(actionButton)

        let viewsDictionary = [
            "avatarImageView": avatarImageView,
            "nicknameLabel": nicknameLabel,
            "stateLabel": stateLabel,
            "actionButton": actionButton,
        ]

        // avatarImageView

        let avatarImageViewCenterY = NSLayoutConstraint(item: avatarImageView, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        let avatarImageViewLeading = NSLayoutConstraint(item: avatarImageView, attribute: .Leading, relatedBy: .Equal, toItem: self, attribute: .Leading, multiplier: 1, constant: YepConfig.chatCellGapBetweenWallAndAvatar())
        let avatarImageViewWidth = NSLayoutConstraint(item: avatarImageView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: YepConfig.chatCellAvatarSize())
        let avatarImageViewHeight = NSLayoutConstraint(item: avatarImageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: YepConfig.chatCellAvatarSize())

        NSLayoutConstraint.activateConstraints([avatarImageViewCenterY, avatarImageViewLeading, avatarImageViewWidth, avatarImageViewHeight])

        // nicknameLabel

        let nicknameLabelTop = NSLayoutConstraint(item: nicknameLabel, attribute: .Top, relatedBy: .Equal, toItem: avatarImageView, attribute: .Top, multiplier: 1, constant: 0)
        let nicknameLabelLeft = NSLayoutConstraint(item: nicknameLabel, attribute: .Left, relatedBy: .Equal, toItem: avatarImageView, attribute: .Right, multiplier: 1, constant: 15)

        NSLayoutConstraint.activateConstraints([nicknameLabelTop, nicknameLabelLeft])
    }
}


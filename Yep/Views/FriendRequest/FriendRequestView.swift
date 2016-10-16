//
//  FriendRequestView.swift
//  Yep
//
//  Created by nixzhu on 15/8/14.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class FriendRequestView: UIView {

    static let height: CGFloat = 60

    enum State {
        case add(prompt: String)
        case consider(prompt: String, friendRequestID: String)

        var prompt: String {
            switch self {
            case .add(let prompt):
                return prompt
            case .consider(let prompt, _):
                return prompt
            }
        }

        var friendRequestID: String? {
            switch self {
            case .consider( _, let friendRequestID):
                return friendRequestID
            default:
                return nil
            }
        }
    }
    let state: State

    init(state: State) {
        self.state = state

        super.init(frame: CGRect.zero)

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

    var addAction: ((FriendRequestView) -> Void)?
    var acceptAction: ((FriendRequestView) -> Void)?
    var rejectAction: ((FriendRequestView) -> Void)?

    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = "NIX"
        label.textColor = UIColor.black.withAlphaComponent(0.9)
        return label
    }()

    lazy var stateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.textColor = UIColor.gray.withAlphaComponent(0.9)
        return label
    }()

    func baseButton() -> UIButton {
        let button = UIButton()
        button.setContentHuggingPriority(300, for: UILayoutConstraintAxis.horizontal)
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 5, right: 15)
        button.setTitleColor(UIColor.white, for: .normal)
        button.setTitleColor(UIColor.gray, for: .highlighted)
        button.setTitleColor(UIColor.lightGray, for: .disabled)
        button.layer.cornerRadius = 5
        return button
    }

    lazy var addButton: UIButton = {
        let button = self.baseButton()
        button.setTitle(NSLocalizedString("button.add", comment: ""), for: .normal)
        button.backgroundColor = UIColor.yepTintColor()
        button.addTarget(self, action: #selector(FriendRequestView.tryAddAction), for: .touchUpInside)
        return button
    }()

    lazy var acceptButton: UIButton = {
        let button = self.baseButton()
        button.setTitle(NSLocalizedString("button.accept", comment: ""), for: .normal)
        button.backgroundColor = UIColor.yepTintColor()
        button.addTarget(self, action: #selector(FriendRequestView.tryAcceptAction), for: .touchUpInside)
        return button
    }()

    lazy var rejectButton: UIButton = {
        let button = self.baseButton()
        button.setTitle(NSLocalizedString("Reject", comment: ""), for: .normal)
        button.backgroundColor = UIColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0)
        button.setTitleColor(UIColor.darkGray, for: .normal)
        button.addTarget(self, action: #selector(FriendRequestView.tryRejectAction), for: .touchUpInside)
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

        backgroundColor = UIColor.clear

        makeUI()
    }

    class ContainerView: UIView {

        override func didMoveToSuperview() {
            super.didMoveToSuperview()

            backgroundColor = UIColor.clear
        }

        override func draw(_ rect: CGRect) {
            super.draw(rect)

            let context = UIGraphicsGetCurrentContext()

            let y = rect.height
            context!.move(to: CGPoint(x: 0, y: y))
            context!.addLine(to: CGPoint(x: rect.width, y: y))

            let bottomLineWidth: CGFloat = 1 / UIScreen.main.scale
            context!.setLineWidth(bottomLineWidth)

            UIColor.lightGray.setStroke()
            
            context!.strokePath()
        }
    }

    func makeUI() {

        let blurEffect = UIBlurEffect(style: .extraLight)
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

        let views: [String: Any] = [
            "visualEffectView": visualEffectView,
            "containerView": containerView,
        ]

        // visualEffectView

        let visualEffectViewConstraintH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[visualEffectView]|", options: [], metrics: nil, views: views)
        let visualEffectViewConstraintV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[visualEffectView]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(visualEffectViewConstraintH)
        NSLayoutConstraint.activate(visualEffectViewConstraintV)

        // containerView

        let containerViewConstraintH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[containerView]|", options: [], metrics: nil, views: views)
        let containerViewConstraintV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[containerView]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activate(containerViewConstraintH)
        NSLayoutConstraint.activate(containerViewConstraintV)

        // avatarImageView

        let avatarImageViewCenterY = NSLayoutConstraint(item: avatarImageView, attribute: .centerY, relatedBy: .equal, toItem: containerView, attribute: .centerY, multiplier: 1, constant: 0)
        let avatarImageViewLeading = NSLayoutConstraint(item: avatarImageView, attribute: .leading, relatedBy: .equal, toItem: containerView, attribute: .leading, multiplier: 1, constant: YepConfig.chatCellGapBetweenWallAndAvatar())
        let avatarImageViewWidth = NSLayoutConstraint(item: avatarImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: YepConfig.chatCellAvatarSize())
        let avatarImageViewHeight = NSLayoutConstraint(item: avatarImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: YepConfig.chatCellAvatarSize())

        NSLayoutConstraint.activate([avatarImageViewCenterY, avatarImageViewLeading, avatarImageViewWidth, avatarImageViewHeight])

        // nicknameLabel

        let nicknameLabelTop = NSLayoutConstraint(item: nicknameLabel, attribute: .top, relatedBy: .equal, toItem: avatarImageView, attribute: .top, multiplier: 1, constant: 0)
        let nicknameLabelLeft = NSLayoutConstraint(item: nicknameLabel, attribute: .left, relatedBy: .equal, toItem: avatarImageView, attribute: .right, multiplier: 1, constant: 8)

        NSLayoutConstraint.activate([nicknameLabelTop, nicknameLabelLeft])

        // stateLabel

        let stateLabelTop = NSLayoutConstraint(item: stateLabel, attribute: .top, relatedBy: .equal, toItem: nicknameLabel, attribute: .bottom, multiplier: 1, constant: 0)
        let stateLabelBottom = NSLayoutConstraint(item: stateLabel, attribute: .bottom, relatedBy: .lessThanOrEqual, toItem: containerView, attribute: .bottom, multiplier: 1, constant: -4)
        let stateLabelLeft = NSLayoutConstraint(item: stateLabel, attribute: .left, relatedBy: .equal, toItem: nicknameLabel, attribute: .left, multiplier: 1, constant: 0)

        NSLayoutConstraint.activate([stateLabelTop, stateLabelBottom, stateLabelLeft])

        switch state {

        case .add:

            // addButton

            addButton.translatesAutoresizingMaskIntoConstraints = false
            addButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            containerView.addSubview(addButton)

            let addButtonTrailing = NSLayoutConstraint(item: addButton, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: -YepConfig.chatCellGapBetweenWallAndAvatar())
            let addButtonCenterY = NSLayoutConstraint(item: addButton, attribute: .centerY, relatedBy: .equal, toItem: containerView, attribute: .centerY, multiplier: 1, constant: 0)

            NSLayoutConstraint.activate([addButtonTrailing, addButtonCenterY])

            // labels' right

            let nicknameLabelRight = NSLayoutConstraint(item: nicknameLabel, attribute: .right, relatedBy: .equal, toItem: addButton, attribute: .left, multiplier: 1, constant: -8)
            let stateLabelRight = NSLayoutConstraint(item: stateLabel, attribute: .right, relatedBy: .equal, toItem: addButton, attribute: .left, multiplier: 1, constant: -8)

            NSLayoutConstraint.activate([nicknameLabelRight, stateLabelRight])

        case .consider:

            // acceptButton

            acceptButton.translatesAutoresizingMaskIntoConstraints = false
            acceptButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            containerView.addSubview(acceptButton)

            let acceptButtonTrailing = NSLayoutConstraint(item: acceptButton, attribute: .trailing, relatedBy: .equal, toItem: containerView, attribute: .trailing, multiplier: 1, constant: -YepConfig.chatCellGapBetweenWallAndAvatar())
            let acceptButtonCenterY = NSLayoutConstraint(item: acceptButton, attribute: .centerY, relatedBy: .equal, toItem: containerView, attribute: .centerY, multiplier: 1, constant: 0)

            NSLayoutConstraint.activate([acceptButtonTrailing, acceptButtonCenterY])

            // rejectButton

            rejectButton.translatesAutoresizingMaskIntoConstraints = false
            rejectButton.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            containerView.addSubview(rejectButton)

            let rejectButtonRight = NSLayoutConstraint(item: rejectButton, attribute: .right, relatedBy: .equal, toItem: acceptButton, attribute: .left, multiplier: 1, constant: -8)
            let rejectButtonCenterY = NSLayoutConstraint(item: rejectButton, attribute: .centerY, relatedBy: .equal, toItem: containerView, attribute: .centerY, multiplier: 1, constant: 0)

            NSLayoutConstraint.activate([rejectButtonRight, rejectButtonCenterY])

            // labels' right

            let nicknameLabelRight = NSLayoutConstraint(item: nicknameLabel, attribute: .right, relatedBy: .equal, toItem: rejectButton, attribute: .left, multiplier: 1, constant: -8)
            let stateLabelRight = NSLayoutConstraint(item: stateLabel, attribute: .right, relatedBy: .equal, toItem: rejectButton, attribute: .left, multiplier: 1, constant: -8)

            NSLayoutConstraint.activate([nicknameLabelRight, stateLabelRight])
        }
    }
}


//
//  MentionView.swift
//  Yep
//
//  Created by nixzhu on 16/1/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Navi

private class MentionUserCell: UITableViewCell {

    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFit
        return imageView
    }()

    lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.blackColor()
        label.font = UIFont.systemFontOfSize(14)
        return label
    }()

    lazy var mentionUsernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.systemFontOfSize(14)
        return label
    }()

    private override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {

        backgroundColor = UIColor.clearColor()

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(mentionUsernameLabel)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nicknameLabel.translatesAutoresizingMaskIntoConstraints = false
        mentionUsernameLabel.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: AnyObject] = [
            "avatarImageView": avatarImageView,
            "nicknameLabel": nicknameLabel,
            "mentionUsernameLabel": mentionUsernameLabel,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-15-[avatarImageView(30)]-15-[nicknameLabel]-[mentionUsernameLabel]-15-|", options: [.AlignAllCenterY], metrics: nil, views: views)

        mentionUsernameLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)

        let avatarImageViewCenterY = NSLayoutConstraint(item: avatarImageView, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0)
        let avatarImageViewHeight = NSLayoutConstraint(item: avatarImageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 30)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints([avatarImageViewCenterY, avatarImageViewHeight])
    }

    func configureWithUsernamePrefixMatchedUser(user: UsernamePrefixMatchedUser) {

        if let avatarURLString = user.avatarURLString {
        let plainAvatar = PlainAvatar(avatarURLString: avatarURLString, avatarStyle: picoAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)
        } else {
            avatarImageView.image = UIImage.yep_defaultAvatar30
        }

        nicknameLabel.text = user.nickname
        mentionUsernameLabel.text = user.mentionUsername
    }
}

final class MentionView: UIView {

    static let height: CGFloat = 125

    var users: [UsernamePrefixMatchedUser] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    var pickUserAction: ((username: String) -> Void)?

    lazy var horizontalLineView: HorizontalLineView = {
        let view = HorizontalLineView()
        view.backgroundColor = UIColor.clearColor()
        view.lineColor = UIColor.lightGrayColor()
        return view
    }()

    static let tableViewRowHeight: CGFloat = 50

    lazy var tableView: UITableView = {
        let tableView = UITableView()

        tableView.backgroundColor = UIColor.clearColor()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)

        let effect = UIBlurEffect(style: .ExtraLight)

        let blurView = UIVisualEffectView(effect: effect)
        tableView.backgroundView = blurView

        tableView.separatorEffect = UIVibrancyEffect(forBlurEffect: effect)

        tableView.registerClassOf(MentionUserCell)

        tableView.rowHeight = MentionView.tableViewRowHeight

        tableView.dataSource = self
        tableView.delegate = self

        return tableView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {

        addSubview(horizontalLineView)
        addSubview(tableView)

        horizontalLineView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: AnyObject] = [
            "horizontalLineView": horizontalLineView,
            "tableView": tableView,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[tableView]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[horizontalLineView(1)][tableView]|", options: [.AlignAllLeading, .AlignAllTrailing], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
    }

    weak var heightConstraint: NSLayoutConstraint?
    weak var bottomConstraint: NSLayoutConstraint?

    func show() {

        let usersCount = users.count
        let height = usersCount >= 3 ? MentionView.height : CGFloat(usersCount) * MentionView.tableViewRowHeight

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = 0
            self?.heightConstraint?.constant = height
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })

        if !users.isEmpty {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
        }
    }

    func hide() {

        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = MentionView.height
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })
    }
}

extension MentionView: UITableViewDataSource, UITableViewDelegate {

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: MentionUserCell = tableView.dequeueReusableCell()
        let user = users[indexPath.row]
        cell.configureWithUsernamePrefixMatchedUser(user)
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        defer {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }

        let username = users[indexPath.row].username
        pickUserAction?(username: username)
    }
}


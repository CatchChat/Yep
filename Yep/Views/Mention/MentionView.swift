//
//  MentionView.swift
//  Yep
//
//  Created by nixzhu on 16/1/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Navi

private class MentionUserCell: UITableViewCell {

    static var reuseIdentifier: String {
        return NSStringFromClass(self)
    }

    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFit
        return imageView
    }()

    lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.blackColor()
        label.font = UIFont.systemFontOfSize(14)
        label.text = "Hello"
        return label
    }()

    lazy var mentionUsernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.systemFontOfSize(14)
        label.text = "@World"
        return label
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(mentionUsernameLabel)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nicknameLabel.translatesAutoresizingMaskIntoConstraints = false
        mentionUsernameLabel.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "avatarImageView": avatarImageView,
            "nicknameLabel": nicknameLabel,
            "mentionUsernameLabel": mentionUsernameLabel,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-15-[avatarImageView(30)]-15-[nicknameLabel]-[mentionUsernameLabel]-15-|", options: [.AlignAllCenterY], metrics: nil, views: views)

        let avatarImageViewCenterY = NSLayoutConstraint(item: avatarImageView, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0)
        let avatarImageViewHeight = NSLayoutConstraint(item: avatarImageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 30)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints([avatarImageViewCenterY, avatarImageViewHeight])
    }

    func configureWithUsernamePrefixMatchedUser(user: UsernamePrefixMatchedUser) {

        let plainAvatar = PlainAvatar(avatarURLString: user.avatarURLString, avatarStyle: picoAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = user.nickname
        mentionUsernameLabel.text = user.mentionUsername
    }
}

class MentionView: UIView {

    static let height: CGFloat = 125

    var users: [UsernamePrefixMatchedUser] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = UIColor.redColor()

        tableView.registerClass(MentionUserCell.self, forCellReuseIdentifier: MentionUserCell.reuseIdentifier)

        tableView.rowHeight = 50

        tableView.dataSource = self
        tableView.delegate = self

        return tableView
    }()

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {
        addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "tableView": tableView,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|[tableView]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraintsWithVisualFormat("V:|[tableView]|", options: [], metrics: nil, views: views)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints(constraintsV)
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
        let cell = tableView.dequeueReusableCellWithIdentifier(MentionUserCell.reuseIdentifier, forIndexPath: indexPath) as! MentionUserCell
        let user = users[indexPath.row]
        cell.configureWithUsernamePrefixMatchedUser(user)
        return cell
    }
}


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
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.black
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    lazy var mentionUsernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.yepTintColor()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    fileprivate override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        makeUI()
    }

    func makeUI() {

        backgroundColor = UIColor.clear

        contentView.addSubview(avatarImageView)
        contentView.addSubview(nicknameLabel)
        contentView.addSubview(mentionUsernameLabel)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nicknameLabel.translatesAutoresizingMaskIntoConstraints = false
        mentionUsernameLabel.translatesAutoresizingMaskIntoConstraints = false

        let views: [String: Any] = [
            "avatarImageView": avatarImageView,
            "nicknameLabel": nicknameLabel,
            "mentionUsernameLabel": mentionUsernameLabel,
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[avatarImageView(30)]-15-[nicknameLabel]-[mentionUsernameLabel]-15-|", options: [.alignAllCenterY], metrics: nil, views: views)

        mentionUsernameLabel.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)

        let avatarImageViewCenterY = NSLayoutConstraint(item: avatarImageView, attribute: .centerY, relatedBy: .equal, toItem: contentView, attribute: .centerY, multiplier: 1.0, constant: 0)
        let avatarImageViewHeight = NSLayoutConstraint(item: avatarImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 30)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate([avatarImageViewCenterY, avatarImageViewHeight])
    }

    func configureWithUsernamePrefixMatchedUser(_ user: UsernamePrefixMatchedUser) {

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

    var pickUserAction: ((_ username: String) -> Void)?

    lazy var horizontalLineView: HorizontalLineView = {
        let view = HorizontalLineView()
        view.backgroundColor = UIColor.clear
        view.lineColor = UIColor.lightGray
        return view
    }()

    static let tableViewRowHeight: CGFloat = 50

    lazy var tableView: UITableView = {
        let tableView = UITableView()

        tableView.backgroundColor = UIColor.clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 0)

        let effect = UIBlurEffect(style: .extraLight)

        let blurView = UIVisualEffectView(effect: effect)
        tableView.backgroundView = blurView

        tableView.separatorEffect = UIVibrancyEffect(blurEffect: effect)

        tableView.registerClassOf(MentionUserCell.self)

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

        let views: [String: Any] = [
            "horizontalLineView": horizontalLineView,
            "tableView": tableView,
        ]

        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: views)
        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|[horizontalLineView(1)][tableView]|", options: [.alignAllLeading, .alignAllTrailing], metrics: nil, views: views)

        NSLayoutConstraint.activate(constraintsH)
        NSLayoutConstraint.activate(constraintsV)
    }

    weak var heightConstraint: NSLayoutConstraint?
    weak var bottomConstraint: NSLayoutConstraint?

    func show() {

        let usersCount = users.count
        let height = usersCount >= 3 ? MentionView.height : CGFloat(usersCount) * MentionView.tableViewRowHeight

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = 0
            self?.heightConstraint?.constant = height
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })

        if !users.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        }
    }

    func hide() {

        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
            self?.bottomConstraint?.constant = MentionView.height
            self?.superview?.layoutIfNeeded()
        }, completion: { _ in })
    }
}

extension MentionView: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MentionUserCell = tableView.dequeueReusableCell()
        let user = users[indexPath.row]
        cell.configureWithUsernamePrefixMatchedUser(user)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }

        let username = users[indexPath.row].username
        pickUserAction?(username)
    }
}


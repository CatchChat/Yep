//
//  MentionView.swift
//  Yep
//
//  Created by nixzhu on 16/1/11.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

private class MentionUserCell: UITableViewCell {

    static var reuseIdentifier: String {
        return NSStringFromClass(self)
    }

    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .ScaleAspectFill
        imageView.backgroundColor = UIColor.blueColor()
        return imageView
    }()

    lazy var nicknameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.blackColor()
        label.font = UIFont.systemFontOfSize(14)
        label.text = "Hello"
        return label
    }()

    lazy var usernameLabel: UILabel = {
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
        contentView.addSubview(usernameLabel)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        nicknameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false

        let views = [
            "avatarImageView": avatarImageView,
            "nicknameLabel": nicknameLabel,
            "usernameLabel": usernameLabel,
        ]

        let constraintsH = NSLayoutConstraint.constraintsWithVisualFormat("H:|-15-[avatarImageView(30)]-15-[nicknameLabel]-[usernameLabel]-15-|", options: [.AlignAllCenterY], metrics: nil, views: views)

        let avatarImageViewCenterY = NSLayoutConstraint(item: avatarImageView, attribute: .CenterY, relatedBy: .Equal, toItem: contentView, attribute: .CenterY, multiplier: 1.0, constant: 0)
        let avatarImageViewHeight = NSLayoutConstraint(item: avatarImageView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 30)

        NSLayoutConstraint.activateConstraints(constraintsH)
        NSLayoutConstraint.activateConstraints([avatarImageViewCenterY, avatarImageViewHeight])
    }
}

class MentionView: UIView {

    static let height: CGFloat = 125

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
        return 10
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(MentionUserCell.reuseIdentifier, forIndexPath: indexPath) as! MentionUserCell
        return cell
    }
}


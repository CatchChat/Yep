//
//  SearchedContactsCell.swift
//  Yep
//
//  Created by NIX on 16/3/24.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SearchedContactsCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel! {
        didSet {
            usernameLabel.font = UIFont.systemFontOfSize(12)
            usernameLabel.textColor = UIColor(red: 0.741, green: 0.765, blue: 0.780, alpha: 1)
        }
    }
    @IBOutlet weak var topRightLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorInset = YepConfig.ContactsCell.separatorInset
    }

    func configureWithUser(user: User) {

        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = user.nickname
        usernameLabel.text = user.username.isEmpty ? nil : "@\(user.username)"

        topRightLabel.text = String(format: NSLocalizedString("Last seen %@", comment: ""), NSDate(timeIntervalSince1970: user.lastSignInUnixTime).timeAgo.lowercaseString)

        infoLabel.text = user.introduction
    }

    func configureWithDiscoveredUser(discoveredUser: DiscoveredUser) {

        let plainAvatar = PlainAvatar(avatarURLString: discoveredUser.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(plainAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = discoveredUser.nickname
        if let username = discoveredUser.username {
            usernameLabel.text = "@\(username)"
        } else {
            usernameLabel.text = nil
        }

        topRightLabel.text = String(format: NSLocalizedString("Last seen %@", comment: ""), NSDate(timeIntervalSince1970: discoveredUser.lastSignInUnixTime).timeAgo.lowercaseString)

        infoLabel.text = discoveredUser.introduction
    }
}


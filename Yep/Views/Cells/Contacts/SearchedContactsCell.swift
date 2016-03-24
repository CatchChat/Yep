//
//  SearchedContactsCell.swift
//  Yep
//
//  Created by NIX on 16/3/24.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchedContactsCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var topRightLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
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

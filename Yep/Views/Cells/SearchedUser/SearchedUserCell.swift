//
//  SearchedUserCell.swift
//  Yep
//
//  Created by NIX on 16/4/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchedUserCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorInset = YepConfig.ContactsCell.separatorInset
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureWithUser(user: User, keyword: String?) {

        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        if let keyword = keyword {
            nicknameLabel.attributedText = user.nickname.yep_hightlightSearchKeyword(keyword)

        } else {
            nicknameLabel.text = user.nickname
        }

        if let mentionUsername = user.mentionedUsername {
            if let keyword = keyword {
                usernameLabel.attributedText = mentionUsername.yep_hightlightSearchKeyword(keyword)

            } else {
                usernameLabel.text = mentionUsername
            }
        }
    }
}

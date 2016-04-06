//
//  SearchedMessageCell.swift
//  Yep
//
//  Created by NIX on 16/4/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class SearchedMessageCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorInset = YepConfig.ContactsCell.separatorInset
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureWithMessage(message: Message, keyword: String?) {

        guard let user = message.fromFriend else {
            return
        }

        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = user.nickname

        if let keyword = keyword {
            messageLabel.attributedText = message.textContent.yep_hightlightSearchKeyword(keyword)

        } else {
            messageLabel.text = message.textContent
        }
    }

    func configureWithUserMessages(userMessages: SearchConversationsViewController.UserMessages, keyword: String?) {

        let user = userMessages.user

        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = user.nickname

        let count = userMessages.messages.count

        if let message = userMessages.messages.first {

            if count > 1 {
                messageLabel.textColor = UIColor.yepTintColor()
                messageLabel.text = "\(count) messages"

            } else {
                messageLabel.textColor = UIColor.blackColor()

                if let keyword = keyword {
                    messageLabel.attributedText = message.textContent.yep_hightlightSearchKeyword(keyword)

                } else {
                    messageLabel.text = message.textContent
                }
            }
        }
    }
}

//
//  SearchedMessageCell.swift
//  Yep
//
//  Created by NIX on 16/4/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class SearchedMessageCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        separatorInset = YepConfig.SearchedItemCell.separatorInset
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
        nicknameLabel.text = nil
        timeLabel.text = nil
        messageLabel.text = nil
    }

    func configureWithMessage(message: Message, keyword: String?) {

        guard let user = message.fromFriend else {
            return
        }

        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = user.nickname

        if let keyword = keyword {
            messageLabel.attributedText = message.textContent.yep_hightlightSearchKeyword(keyword, baseFont: YepConfig.SearchedItemCell.messageFont, baseColor: YepConfig.SearchedItemCell.messageColor)

        } else {
            messageLabel.text = message.textContent
        }

        timeLabel.text = NSDate(timeIntervalSince1970: message.createdUnixTime).timeAgo.lowercaseString
    }

    func configureWithUserMessages(userMessages: SearchConversationsViewController.UserMessages, keyword: String?) {

        let user = userMessages.user

        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: nanoAvatarStyle)
        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        nicknameLabel.text = user.nickname

        let count = userMessages.messages.count

        if let message = userMessages.messages.first {

            if count > 1 {
                messageLabel.textColor = UIColor.yepTintColor()
                messageLabel.text = String(format: NSLocalizedString("countMessages%d", comment: ""), count)

                timeLabel.hidden = true
                timeLabel.text = nil

            } else {
                messageLabel.textColor = UIColor.blackColor()

                if let keyword = keyword {
                    messageLabel.attributedText = message.textContent.yep_hightlightSearchKeyword(keyword, baseFont: YepConfig.SearchedItemCell.messageFont, baseColor: YepConfig.SearchedItemCell.messageColor)

                } else {
                    messageLabel.text = message.textContent
                }

                timeLabel.hidden = false
                timeLabel.text = NSDate(timeIntervalSince1970: message.createdUnixTime).timeAgo.lowercaseString
            }
        }
    }
}


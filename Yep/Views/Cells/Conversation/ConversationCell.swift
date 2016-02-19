//
//  ConversationCell.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

class ConversationCell: UITableViewCell {

    var conversation: Conversation!

    var countOfUnreadMessages = 0 {
        didSet {
            let hidden = countOfUnreadMessages == 0

            redDotImageView.hidden = hidden
            unreadCountLabel.hidden = hidden

            unreadCountLabel.text = "\(countOfUnreadMessages)"
        }
    }

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var redDotImageView: UIImageView!
    @IBOutlet weak var unreadCountLabel: UILabel!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chatLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!

    deinit {

//        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        avatarImageView.contentMode = .ScaleAspectFill
        avatarImageViewWidthConstraint.constant = YepConfig.ConversationCell.avatarSize

//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updateUIButAvatar:", name: YepConfig.Notification.newMessages, object: nil)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        avatarImageView.image = nil
        nameLabel.text = nil
        chatLabel.text = nil
        timeAgoLabel.text = nil

        countOfUnreadMessages = 0
    }

//    func updateUIButAvatar(sender: NSNotification) {
//
//        updateCountOfUnreadMessages()
//        updateInfoLabels()
//    }

    private func updateCountOfUnreadMessages() {

        if !conversation.invalidated {
            countOfUnreadMessages = countOfUnreadMessagesInConversation(conversation)
        }
    }

    func updateInfoLabels() {

        if let latestValidMessage = conversation.latestValidMessage {

            if let mediaType = MessageMediaType(rawValue: latestValidMessage.mediaType), placeholder = mediaType.placeholder {
                self.chatLabel.text = placeholder
            } else {
                self.chatLabel.text = latestValidMessage.textContent
            }

            let createdAt = NSDate(timeIntervalSince1970: latestValidMessage.createdUnixTime)
            self.timeAgoLabel.text = createdAt.timeAgo

        } else {
            self.chatLabel.text = NSLocalizedString("No messages yet.", comment: "")
            self.timeAgoLabel.text = NSDate(timeIntervalSince1970: conversation.updatedUnixTime).timeAgo
        }
    }

    func configureWithConversation(conversation: Conversation, avatarRadius radius: CGFloat, tableView: UITableView, indexPath: NSIndexPath) {
        
        self.conversation = conversation

        updateCountOfUnreadMessages()
        
        if conversation.type == ConversationType.OneToOne.rawValue {

            if let conversationWithFriend = conversation.withFriend {

                self.nameLabel.text = conversationWithFriend.nickname

                let userAvatar = UserAvatar(userID: conversationWithFriend.userID, avatarURLString: conversationWithFriend.avatarURLString, avatarStyle: miniAvatarStyle)
                avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

                updateInfoLabels()
            }

        } else { // Group Conversation

            if let group = conversation.withGroup {

                if !group.groupName.isEmpty {
                    nameLabel.text = group.groupName

                } else {
                    if let feed = group.withFeed {
                        nameLabel.text = feed.body
                    }
                }

                if let user = group.owner {
                    let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
                    avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

                } else {

                    if let user = group.withFeed?.creator {
                        let userAvatar = UserAvatar(userID: user.userID, avatarURLString: user.avatarURLString, avatarStyle: miniAvatarStyle)
                        avatarImageView.navi_setAvatar(userAvatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

                    } else {
                        avatarImageView.image = UIImage(named: "default_avatar_60")
                    }
                }

                updateInfoLabels()
            }
        }
    }
}


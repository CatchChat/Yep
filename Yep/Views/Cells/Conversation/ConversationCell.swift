//
//  ConversationCell.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

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

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        avatarImageView.contentMode = .ScaleAspectFill
        avatarImageViewWidthConstraint.constant = YepConfig.ConversationCell.avatarSize
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureWithConversation(conversation: Conversation, avatarRadius radius: CGFloat, tableView: UITableView, indexPath: NSIndexPath) {
        
        self.conversation = conversation

        countOfUnreadMessages = countOfUnreadMessagesInConversation(conversation)
        
        if conversation.type == ConversationType.OneToOne.rawValue {

            if let conversationWithFriend = conversation.withFriend {

                self.nameLabel.text = conversationWithFriend.nickname

                AvatarCache.sharedInstance.roundAvatarOfUser(conversationWithFriend, withRadius: radius) { [weak self] roundImage in
                    dispatch_async(dispatch_get_main_queue()) {
                        if let _ = tableView.cellForRowAtIndexPath(indexPath) {
                            self?.avatarImageView.image = roundImage
                        }
                    }
                }

                if let latestMessage = messagesInConversation(conversation).last {
                    
                    switch latestMessage.mediaType {

                    case MessageMediaType.Audio.rawValue:
                        self.chatLabel.text = NSLocalizedString("[Audio]", comment: "")
                    case MessageMediaType.Video.rawValue:
                        self.chatLabel.text = NSLocalizedString("[Video]", comment: "")
                    case MessageMediaType.Image.rawValue:
                        self.chatLabel.text = NSLocalizedString("[Image]", comment: "")
                    case MessageMediaType.Location.rawValue:
                        self.chatLabel.text = NSLocalizedString("[Location]", comment: "")
                    case MessageMediaType.Text.rawValue:
                        self.chatLabel.text = latestMessage.textContent
                    default:
                        self.chatLabel.text = "I love NIX."

                    }

                    let createdAt = NSDate(timeIntervalSince1970: latestMessage.createdUnixTime)
                    self.timeAgoLabel.text = createdAt.timeAgo

                } else {
                    self.chatLabel.text = NSLocalizedString("No messages yet.", comment: "")
                    self.timeAgoLabel.text = NSLocalizedString("None", comment: "")
                }
            }

        } else { // Group Conversation

            if let group = conversation.withGroup {
                self.nameLabel.text = group.groupName
            } else {
                self.nameLabel.text = ""
            }

            if let latestMessage = messagesInConversation(conversation).last {
                if let messageSender = latestMessage.fromFriend {
                    AvatarCache.sharedInstance.roundAvatarOfUser(messageSender, withRadius: radius) { [weak self] roundImage in
                        dispatch_async(dispatch_get_main_queue()) {
                            self?.avatarImageView.image = roundImage
                        }
                    }
                }

                switch latestMessage.mediaType {

                case MessageMediaType.Audio.rawValue:
                    self.chatLabel.text = NSLocalizedString("[Audio]", comment: "")
                case MessageMediaType.Video.rawValue:
                    self.chatLabel.text = NSLocalizedString("[Video]", comment: "")
                case MessageMediaType.Image.rawValue:
                    self.chatLabel.text = NSLocalizedString("[Image]", comment: "")
                case MessageMediaType.Location.rawValue:
                    self.chatLabel.text = NSLocalizedString("[Location]", comment: "")
                case MessageMediaType.Text.rawValue:
                    self.chatLabel.text = latestMessage.textContent
                default:
                    self.chatLabel.text = "We love NIX."

                }

                let createdAt = NSDate(timeIntervalSince1970: latestMessage.createdUnixTime)
                self.timeAgoLabel.text = createdAt.timeAgo

            } else {
                self.avatarImageView.image = AvatarCache.sharedInstance.defaultRoundAvatarOfRadius(radius)

                self.chatLabel.text = NSLocalizedString("No messages yet.", comment: "")
                self.timeAgoLabel.text = NSLocalizedString("None", comment: "")
            }
        }
    }
}

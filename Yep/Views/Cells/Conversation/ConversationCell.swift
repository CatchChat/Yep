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

                    if let mediaType = MessageMediaType(rawValue: latestMessage.mediaType), placeholder = mediaType.placeholder {
                        self.chatLabel.text = placeholder
                    } else {
                        self.chatLabel.text = latestMessage.textContent
                    }

                    let createdAt = NSDate(timeIntervalSince1970: latestMessage.createdUnixTime)
                    self.timeAgoLabel.text = createdAt.timeAgo

                } else {
                    self.chatLabel.text = NSLocalizedString("No messages yet.", comment: "")
                    self.timeAgoLabel.text = NSDate(timeIntervalSince1970: conversation.updatedUnixTime).timeAgo
                }
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
                
                if let latestMessage = messagesInConversation(conversation).last {

                    if let mediaType = MessageMediaType(rawValue: latestMessage.mediaType), placeholder = mediaType.placeholder {
                        self.chatLabel.text = placeholder
                    } else {
                        self.chatLabel.text = latestMessage.textContent
                    }

                    let createdAt = NSDate(timeIntervalSince1970: latestMessage.createdUnixTime)
                    self.timeAgoLabel.text = createdAt.timeAgo
                    
                } else {
                    self.chatLabel.text = NSLocalizedString("No messages yet.", comment: "")
                    self.timeAgoLabel.text = NSDate(timeIntervalSince1970: group.createdUnixTime).timeAgo
                }

                if let user = group.owner {
                    AvatarCache.sharedInstance.roundAvatarOfUser(user, withRadius: radius, completion: {[weak self] image in
                        dispatch_async(dispatch_get_main_queue()) {
                            if let _ = tableView.cellForRowAtIndexPath(indexPath) {
                                self?.avatarImageView.image = image
                            }
                        }
                    })
                }

                /*
                if let feed = group.withFeed {

                    if let user = feed.creator {
                        AvatarCache.sharedInstance.roundAvatarOfUser(user, withRadius: radius, completion: {[weak self] image in
                            dispatch_async(dispatch_get_main_queue()) {
                                if let _ = tableView.cellForRowAtIndexPath(indexPath) {
                                    self?.avatarImageView.image = image
                                }
                            }
                        })
                    }

                    /*
                    if let URL = feed.attachments.first?.URLString {
                        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(URL, withRadius: radius, completion: {[weak self] (image) -> Void in
                            dispatch_async(dispatch_get_main_queue()) {
                                if let _ = tableView.cellForRowAtIndexPath(indexPath) {
                                    self?.avatarImageView.image = image
                                }
                            }
                        })
                    } else {
                        if let user = feed.creator {
                            AvatarCache.sharedInstance.roundAvatarOfUser(user, withRadius: radius, completion: {[weak self] image in
                                dispatch_async(dispatch_get_main_queue()) {
                                    if let _ = tableView.cellForRowAtIndexPath(indexPath) {
                                        self?.avatarImageView.image = image
                                    }
                                }
                            })
                        }
                    }
                    */

                } else {
                    if let avatarURL = group.owner?.avatarURLString {
                        AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURL, withRadius: radius, completion: {[weak self] image in
                            dispatch_async(dispatch_get_main_queue()) {
                                if let _ = tableView.cellForRowAtIndexPath(indexPath) {
                                    self?.avatarImageView.image = image
                                }
                            }
                        })
                    }
                }
                */
            }
        }
    }
}


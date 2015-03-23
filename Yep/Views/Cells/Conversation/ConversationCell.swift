//
//  ConversationCell.swift
//  Yep
//
//  Created by NIX on 15/3/16.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ConversationCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chatLabel: UILabel!
    @IBOutlet weak var timeAgoLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code

        avatarImageView.contentMode = .ScaleAspectFill
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureWithConversation(conversation: Conversation, avatarRadius radius: CGFloat) {
        
        if conversation.type == ConversationType.OneToOne.rawValue {

            if let conversationWithFriend = conversation.withFriend {

                self.nameLabel.text = conversationWithFriend.nickname

                AvatarCache.sharedInstance.roundAvatarOfUser(conversationWithFriend, withRadius: radius) { roundImage in
                    dispatch_async(dispatch_get_main_queue()) {
                        self.avatarImageView.image = roundImage
                    }
                }

                if let latestMessage = conversation.messages.last {
                    self.chatLabel.text = latestMessage.textContent
                    self.timeAgoLabel.text = "\(latestMessage.createdAt)"
                } else {
                    self.chatLabel.text = ""
                    self.timeAgoLabel.text = "None"
                }
            }

        } else { // Group Conversation

            if let group = conversation.withGroup {
                self.nameLabel.text = group.groupName
            } else {
                self.nameLabel.text = ""
            }

            if let latestMessage = conversation.messages.last {
                if let messageSender = latestMessage.fromFriend {
                    AvatarCache.sharedInstance.roundAvatarOfUser(messageSender, withRadius: radius) { roundImage in
                        dispatch_async(dispatch_get_main_queue()) {
                            self.avatarImageView.image = roundImage
                        }
                    }
                }

                self.chatLabel.text = latestMessage.textContent
                self.timeAgoLabel.text = "\(latestMessage.createdAt)"

            } else {
                self.avatarImageView.image = AvatarCache.sharedInstance.defaultRoundAvatarOfRadius(radius)

                self.chatLabel.text = ""
                self.timeAgoLabel.text = "None"
            }
        }
    }
}

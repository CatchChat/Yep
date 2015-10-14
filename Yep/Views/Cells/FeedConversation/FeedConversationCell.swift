//
//  FeedConversationCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/12.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedConversationCell: UITableViewCell {

    @IBOutlet weak var mediaView: FeedMediaView!
    @IBOutlet weak var redDotImageView: UIImageView!
    @IBOutlet weak var unreadCountLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chatLabel: UILabel!
    @IBOutlet weak var accessoryImageView: UIImageView!

    var conversation: Conversation!

    var countOfUnreadMessages = 0 {
        didSet {
            let hidden = countOfUnreadMessages == 0

            redDotImageView.hidden = hidden
            unreadCountLabel.hidden = hidden

            unreadCountLabel.text = "\(countOfUnreadMessages)"
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        mediaView.hidden = true
    }

    func configureWithConversation(conversation: Conversation) {

        self.conversation = conversation

        countOfUnreadMessages = countOfUnreadMessagesInConversation(conversation)

        if let feed = conversation.withGroup?.withFeed {
            nameLabel.text = feed.body

            let attachmentURLs = feed.attachments.map({ NSURL(string: $0.URLString) }).flatMap({ $0 })
            mediaView.setImagesWithURLs(attachmentURLs)
        }

        if let latestMessage = messagesInConversation(conversation).last {

            if let mediaType = MessageMediaType(rawValue: latestMessage.mediaType), placeholder = mediaType.placeholder {
                self.chatLabel.text = placeholder
            } else {
                self.chatLabel.text = latestMessage.textContent
            }

        } else {
            self.chatLabel.text = NSLocalizedString("No messages yet.", comment: "")
        }
    }
}

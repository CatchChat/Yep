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
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chatLabel: UILabel!
    @IBOutlet weak var redDotImageView: UIImageView!
    @IBOutlet weak var accessoryImageView: UIImageView!

    var conversation: Conversation!

    var countOfUnreadMessages = 0 {
        didSet {
            let hidden = countOfUnreadMessages == 0

            redDotImageView.hidden = hidden
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
        
        mediaView.imageView1.image = nil
        mediaView.imageView2.image = nil
        mediaView.imageView3.image = nil
        mediaView.imageView4.image = nil
    }

    func configureWithConversation(conversation: Conversation) {

        self.conversation = conversation

        guard let feed = conversation.withGroup?.withFeed else {
            return
        }

        countOfUnreadMessages = countOfUnreadMessagesInConversation(conversation)
        //countOfUnreadMessages = conversation.unreadMessagesCount

        nameLabel.text = feed.body

        let attachments = feed.attachments.map({
            //DiscoveredAttachment(kind: AttachmentKind(rawValue: $0.kind)!, metadata: $0.metadata, URLString: $0.URLString)
            DiscoveredAttachment( metadata: $0.metadata, URLString: $0.URLString)
        })
        mediaView.setImagesWithAttachments(attachments)

        if let latestValidMessage = conversation.latestValidMessage {

            if let mediaType = MessageMediaType(rawValue: latestValidMessage.mediaType), placeholder = mediaType.placeholder {
                self.chatLabel.text = placeholder
            } else {
                self.chatLabel.text = latestValidMessage.nicknameWithTextContent
            }
            
        } else {
            self.chatLabel.text = NSLocalizedString("No messages yet.", comment: "")
        }
    }
}


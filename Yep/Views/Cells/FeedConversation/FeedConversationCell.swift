//
//  FeedConversationCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/12.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class FeedConversationCell: UITableViewCell {

    @IBOutlet weak var mediaView: FeedMediaView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chatLabel: UILabel!
    @IBOutlet weak var redDotImageView: UIImageView!
    @IBOutlet weak var accessoryImageView: UIImageView!

    var conversation: Conversation!

    fileprivate var hasUnreadMessages: Bool = false {
        didSet {
            redDotImageView.isHidden = !hasUnreadMessages
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        
        mediaView.isHidden = true
        
        mediaView.clearImages()
    }

    func configureWithConversation(_ conversation: Conversation) {

        self.conversation = conversation

        guard let feed = conversation.withGroup?.withFeed else {
            return
        }

        hasUnreadMessages = conversation.hasUnreadMessages
        //countOfUnreadMessages = countOfUnreadMessagesInConversation(conversation)
        //countOfUnreadMessages = conversation.unreadMessagesCount

        nameLabel.text = feed.body

        let attachments: [DiscoveredAttachment] = feed.attachments.map({
            DiscoveredAttachment(metadata: $0.metadata, URLString: $0.URLString, image: nil)
        })
        mediaView.setImagesWithAttachments(attachments)

        if let latestValidMessage = conversation.latestValidMessage {

            if let mediaType = MessageMediaType(rawValue: latestValidMessage.mediaType), let placeholder = mediaType.placeholder {
                self.chatLabel.text = placeholder

            } else {
                if conversation.mentionedMe {
                    let mentionedYouString = NSLocalizedString("[Mentioned you]", comment: "")
                    let string = mentionedYouString + " " + latestValidMessage.nicknameWithTextContent

                    let attributedString = NSMutableAttributedString(string: string)
                    let mentionedYouRange = NSMakeRange(0, (mentionedYouString as NSString).length)
                    attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor.red, range: mentionedYouRange)

                    self.chatLabel.attributedText = attributedString

                } else {
                    self.chatLabel.text = latestValidMessage.nicknameWithTextContent
                }
            }
            
        } else {
            self.chatLabel.text = String.trans_promptNoMessages
        }
    }
}


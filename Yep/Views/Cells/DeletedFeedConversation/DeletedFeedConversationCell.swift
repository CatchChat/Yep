//
//  DeletedFeedConversationCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/29.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class DeletedFeedConversationCell: UITableViewCell {

    @IBOutlet weak var typeImageView: UIImageView!
    @IBOutlet weak var deletedPromptLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chatLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        deletedPromptLabel.text = NSLocalizedString("[Deleted]", comment: "")
        deletedPromptLabel.textColor = UIColor.lightGrayColor()

        selectionStyle = .None
    }

    func configureWithConversation(conversation: Conversation) {

        guard let feed = conversation.withGroup?.withFeed else {
            return
        }

        nameLabel.text = feed.body
        chatLabel.text = NSLocalizedString("Feed has been deleted by creator.", comment: "")
    }
}

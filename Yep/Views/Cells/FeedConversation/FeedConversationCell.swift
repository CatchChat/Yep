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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }


    func configureWithConversation(conversation: Conversation) {

        //self.conversation = conversation

        //countOfUnreadMessages = countOfUnreadMessagesInConversation(conversation)

        nameLabel.text = conversation.withGroup?.withFeed?.body
    }
}

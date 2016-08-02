//
//  FeedConversationDockCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/12.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

final class FeedConversationDockCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var chatLabel: UILabel!
    @IBOutlet weak var redDotImageView: UIImageView!
    @IBOutlet weak var accessoryImageView: UIImageView!

    var haveGroupUnreadMessages = false {
        willSet {
            redDotImageView.hidden = !newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        nameLabel.text = NSLocalizedString("Joined Feeds", comment: "")
        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
    }
}


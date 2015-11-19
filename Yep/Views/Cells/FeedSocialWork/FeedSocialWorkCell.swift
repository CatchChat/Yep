//
//  FeedSocialWorkCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/19.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedSocialWorkCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var skillBubbleImageView: UIImageView!
    @IBOutlet weak var skillLabel: UILabel!

    @IBOutlet weak var messageTextView: FeedTextView!
    @IBOutlet weak var messageTextViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var socialWorkContainerView: UIView!
    @IBOutlet weak var socialWorkImageView: UIImageView!
    @IBOutlet weak var githubRepoContainerView: UIView!
    @IBOutlet weak var githubRepoImageView: UIImageView!
    @IBOutlet weak var githubRepoNameLabel: UILabel!
    @IBOutlet weak var githubRepoDescriptionLabel: UILabel!

    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dotLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!

    @IBOutlet weak var messageCountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

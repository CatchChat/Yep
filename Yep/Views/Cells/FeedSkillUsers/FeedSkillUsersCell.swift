//
//  FeedSkillUsersCell.swift
//  Yep
//
//  Created by nixzhu on 15/10/23.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit

class FeedSkillUsersCell: UITableViewCell {

    @IBOutlet weak var promptLabel: UILabel!

    @IBOutlet weak var avatarImageView1: UIImageView!
    @IBOutlet weak var avatarImageView2: UIImageView!
    @IBOutlet weak var avatarImageView3: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}


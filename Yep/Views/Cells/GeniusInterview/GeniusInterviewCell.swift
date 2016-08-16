//
//  GeniusInterviewCell.swift
//  Yep
//
//  Created by NIX on 16/5/27.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Navi

class GeniusInterviewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var numberLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var accessoryImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        numberLabel.font = UIFont.systemFontOfSize(16)
        numberLabel.textColor = UIColor.yepTintColor()

        titleLabel.font = UIFont.systemFontOfSize(16)
        titleLabel.textColor = UIColor.blackColor()

        detailLabel.font = UIFont.systemFontOfSize(13)
        detailLabel.textColor = UIColor(red: 142/255.0, green: 142/255.0, blue: 147/255.0, alpha: 1)

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
    }

    func configure(withGeniusInterview geniusInterview: GeniusInterview) {

        let avatar = PlainAvatar(avatarURLString: geniusInterview.user.avatarURLString, avatarStyle: miniAvatarStyle)
        avatarImageView.navi_setAvatar(avatar, withFadeTransitionDuration: avatarFadeTransitionDuration)

        numberLabel.text = String(format: "#%02d", geniusInterview.number)
        titleLabel.text = geniusInterview.title
        detailLabel.text = geniusInterview.detail
    }
}


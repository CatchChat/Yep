//
//  SettingsUserCell.swift
//  Yep
//
//  Created by NIX on 15/4/24.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class SettingsUserCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameLabel: UILabel!

    @IBOutlet weak var introLabel: UILabel!

    @IBOutlet weak var accessoryImageView: UIImageView!


    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let avatarSize = YepConfig.Settings.userCellAvatarSize
        avatarImageViewWidthConstraint.constant = avatarSize

        YepUserDefaults.avatarURLString.bindAndFireListener("SettingsUserCell.Avatar") { _ in
            self.updateAvatar()
        }

        YepUserDefaults.nickname.bindAndFireListener("SettingsUserCell.Nickname") { nickname in
            self.nameLabel.text = nickname
        }

        introLabel.font = YepConfig.Settings.introFont

        accessoryImageView.tintColor = UIColor.lightGrayColor()

    }

    func updateAvatar() {

        if let avatarURLString = YepUserDefaults.avatarURLString.value {

            let avatarSize = YepConfig.Settings.userCellAvatarSize

            avatarImageView.alpha = 0
            AvatarCache.sharedInstance.roundAvatarWithAvatarURLString(avatarURLString, withRadius: avatarSize * 0.5) { image in
                dispatch_async(dispatch_get_main_queue()) {
                    self.avatarImageView.image = image

                    UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: { () -> Void in
                        self.avatarImageView.alpha = 1
                    }, completion: { (finished) -> Void in
                    })
                }
            }
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

//
//  ProfileSocialAccountBlogCell.swift
//  Yep
//
//  Created by NIX on 16/5/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileSocialAccountBlogCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconImageViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var blogLabel: UILabel!

    @IBOutlet weak var accessoryImageView: UIImageView!
    @IBOutlet weak var accessoryImageViewTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
        iconImageViewLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.rightEdgeInset

        accessoryImageView.hidden = true
    }

    func configureWithProfileUser(profileUser: ProfileUser?) {

        iconImageView.image = UIImage(named: "icon_dribbble")
        nameLabel.text = "Blog"

        iconImageView.tintColor = SocialAccount.disabledColor
        nameLabel.textColor = SocialAccount.disabledColor
        blogLabel.textColor = SocialAccount.disabledColor
    }
}


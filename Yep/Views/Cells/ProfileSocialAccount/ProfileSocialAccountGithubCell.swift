//
//  ProfileSocialAccountGithubCell.swift
//  Yep
//
//  Created by NIX on 15/5/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileSocialAccountGithubCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconImageViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameLabel: UILabel!


    @IBOutlet weak var reposImageView: UIImageView!

    @IBOutlet weak var reposCountLabel: UILabel!

    @IBOutlet weak var followersImageView: UIImageView!

    @IBOutlet weak var followersCountLabel: UILabel!

    @IBOutlet weak var accessoryImageView: UIImageView!
    @IBOutlet weak var accessoryImageViewTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryImageView.tintColor = UIColor.lightGrayColor()
        iconImageViewLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.rightEdgeInset
    }

}

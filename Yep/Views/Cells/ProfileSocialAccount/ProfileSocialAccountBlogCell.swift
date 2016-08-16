//
//  ProfileSocialAccountBlogCell.swift
//  Yep
//
//  Created by NIX on 16/5/5.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

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

        iconImageView.image = UIImage.yep_iconBlog
        nameLabel.text = "Blog"
        blogLabel.text = nil

        accessoryImageView.hidden = true
    }

    var blogString: String? {

        didSet {
            blogLabel.text = blogString

            if let _ = blogString {

                iconImageView.tintColor = UIColor.yepTintColor()
                nameLabel.textColor = UIColor.yepTintColor()
                blogLabel.textColor = SocialAccount.disabledColor

                accessoryImageView.hidden = false

            } else {
                iconImageView.tintColor = SocialAccount.disabledColor
                nameLabel.textColor = SocialAccount.disabledColor
                blogLabel.textColor = SocialAccount.disabledColor
                
                accessoryImageView.hidden = true
            }
        }
    }

    func configureWithProfileUser(profileUser: ProfileUser?) {

        if profileUser?.isMe ?? false {
            blogString = YepUserDefaults.blogString

        } else {
            blogString = profileUser?.blogTitle ?? profileUser?.blogURL?.absoluteString
        }
    }
}


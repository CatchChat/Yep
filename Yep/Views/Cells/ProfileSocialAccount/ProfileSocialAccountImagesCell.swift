//
//  ProfileSocialAccountImagesCell.swift
//  Yep
//
//  Created by NIX on 15/5/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileSocialAccountImagesCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconImageViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameLabel: UILabel!

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!

    @IBOutlet weak var accessoryImageView: UIImageView!
    @IBOutlet weak var accessoryImageViewTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryImageView.tintColor = UIColor.lightGrayColor()
        iconImageViewLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.rightEdgeInset
    }

    func configureWithProfileUser(profileUser: ProfileUser?, orSocialWorkProviderInfo socialWorkProviderInfo: ProfileViewController.SocialWorkProviderInfo, socialAccount: SocialAccount, socialWork: SocialWork?, completion: ((SocialWork) -> Void)?) {

        iconImageView.image = UIImage(named: socialAccount.iconName)
        nameLabel.text = socialAccount.description

        iconImageView.tintColor = UIColor.lightGrayColor()
        nameLabel.textColor = UIColor.lightGrayColor()

        let providerName = socialAccount.description.lowercaseString

        if let profileUser = profileUser {

            switch profileUser {

            case .DiscoveredUserType(let discoveredUser):
                for provider in discoveredUser.socialAccountProviders {
                    if (provider.name == providerName) && provider.enabled {
                        iconImageView.tintColor = socialAccount.tintColor
                        nameLabel.textColor = socialAccount.tintColor

                        break
                    }
                }

            case .UserType(let user):
                for provider in user.socialAccountProviders {
                    if (provider.name == providerName) && provider.enabled {
                        iconImageView.tintColor = socialAccount.tintColor
                        nameLabel.textColor = socialAccount.tintColor

                        break
                    }
                }
            }

        } else {
            if let enabled = socialWorkProviderInfo[providerName] {
                if enabled {
                    iconImageView.tintColor = socialAccount.tintColor
                    nameLabel.textColor = socialAccount.tintColor
                }
            }
        }
    }
}

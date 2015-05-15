//
//  ProfileSocialAccountGithubCell.swift
//  Yep
//
//  Created by NIX on 15/5/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit

class ProfileSocialAccountGithubCell: UICollectionViewCell {

    var githubWork: GithubWork? {
        didSet {
            if let work = githubWork {
                let user = work.user
                reposCountLabel.text = "\(user.publicReposCount)"
                followersCountLabel.text = "\(user.followersCount)"
            }
        }
    }

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

    func configureWithProfileUser(profileUser: ProfileUser?, orSocialWorkProviderInfo socialWorkProviderInfo: ProfileViewController.SocialWorkProviderInfo, socialAccount: SocialAccount, githubWork: GithubWork?, completion: ((GithubWork) -> Void)?) {

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


        if let githubWork = githubWork {
            self.githubWork = githubWork

        } else {
            var userID: String?

            if let profileUser = profileUser {
                switch profileUser {
                case .DiscoveredUserType(let discoveredUser):
                    userID = discoveredUser.id
                case .UserType(let user):
                    userID = user.userID
                }

            } else {
                userID = YepUserDefaults.userID.value
            }

            if let userID = userID {

                githubWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                    defaultFailureHandler(reason, errorMessage)

                }, completion: { githubWork in
                    println("githubWork: \(githubWork)")

                    dispatch_async(dispatch_get_main_queue()) {
                        self.githubWork = githubWork
                    }
                })
            }
        }
    }

}

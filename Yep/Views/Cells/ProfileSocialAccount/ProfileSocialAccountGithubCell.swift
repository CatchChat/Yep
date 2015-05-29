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
                reposImageView.hidden = false
                starsImageView.hidden = false
                accessoryImageView.hidden = false

                let user = work.user
                reposCountLabel.text = "\(user.publicReposCount)"

                let repos = work.repos
                let starsCount = repos.reduce(0, combine: { (result, repo) -> Int in
                    result + repo.stargazersCount
                })
                starsCountLabel.text = "\(starsCount)"
            }
        }
    }

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconImageViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameLabel: UILabel!

    @IBOutlet weak var reposImageView: UIImageView!
    @IBOutlet weak var reposCountLabel: UILabel!
    @IBOutlet weak var starsImageView: UIImageView!
    @IBOutlet weak var starsCountLabel: UILabel!

    @IBOutlet weak var accessoryImageView: UIImageView!
    @IBOutlet weak var accessoryImageViewTrailingConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()

        reposImageView.tintColor = UIColor.darkGrayColor()
        starsImageView.tintColor = UIColor.darkGrayColor()

        reposCountLabel.textColor = UIColor.grayColor()
        starsCountLabel.textColor = UIColor.grayColor()

        accessoryImageView.tintColor = UIColor.lightGrayColor()

        iconImageViewLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.rightEdgeInset
    }

    func configureWithProfileUser(profileUser: ProfileUser?, socialAccount: SocialAccount, githubWork: GithubWork?, completion: ((GithubWork) -> Void)?) {

        iconImageView.image = UIImage(named: socialAccount.iconName)
        nameLabel.text = socialAccount.description

        iconImageView.tintColor = UIColor.grayColor()
        nameLabel.textColor = UIColor.grayColor()

        let providerName = socialAccount.description.lowercaseString

        var accountEnabled = false

        if let profileUser = profileUser {
            accountEnabled = profileUser.enabledSocialAccount(socialAccount)

            if accountEnabled {
                iconImageView.tintColor = socialAccount.tintColor
                nameLabel.textColor = socialAccount.tintColor
            }
        }
        
        if !accountEnabled {
            reposImageView.hidden = true
            reposCountLabel.text = ""
            starsImageView.hidden = true
            starsCountLabel.text = ""

            accessoryImageView.hidden = true

        } else {
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
                }

                if let userID = userID {

                    githubWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                        defaultFailureHandler(reason, errorMessage)

                    }, completion: { githubWork in
                        //println("githubWork: \(githubWork)")

                        dispatch_async(dispatch_get_main_queue()) {
                            self.githubWork = githubWork

                            completion?(githubWork)
                        }
                    })
                }
            }
        }
    }

}

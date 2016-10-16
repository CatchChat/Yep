//
//  ProfileSocialAccountGithubCell.swift
//  Yep
//
//  Created by NIX on 15/5/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ProfileSocialAccountGithubCell: UICollectionViewCell {

    var githubWork: GithubWork? {
        didSet {
            if let work = githubWork {

                let user = work.user
                reposCountLabel.text = "\(user.publicReposCount)"

                let repos = work.repos
                let starsCount = repos.reduce(0, { (result, repo) -> Int in
                    result + repo.stargazersCount
                })
                starsCountLabel.text = "\(starsCount)"

                showDefail()
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

        reposImageView.tintColor = UIColor.yepIconImageViewTintColor()
        starsImageView.tintColor = UIColor.yepIconImageViewTintColor()

        reposCountLabel.textColor = UIColor.gray
        starsCountLabel.textColor = UIColor.gray

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()

        iconImageViewLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.rightEdgeInset

        hideDetail()
    }

    func hideDetail() {
        reposImageView.isHidden = true
        reposCountLabel.isHidden = true
        starsImageView.isHidden = true
        starsCountLabel.isHidden = true

        accessoryImageView.isHidden = true
    }

    func showDefail() {
        reposImageView.isHidden = false
        reposCountLabel.isHidden = false
        starsImageView.isHidden = false
        starsCountLabel.isHidden = false

        accessoryImageView.isHidden = false
    }

    func configureWithProfileUser(_ profileUser: ProfileUser?, socialAccount: SocialAccount, githubWork: GithubWork?, completion: ((GithubWork) -> Void)?) {

        iconImageView.image = UIImage(named: socialAccount.iconName)
        nameLabel.text = socialAccount.name

        iconImageView.tintColor = SocialAccount.disabledColor
        nameLabel.textColor = SocialAccount.disabledColor

        var accountEnabled = false

        if let profileUser = profileUser {
            accountEnabled = profileUser.enabledSocialAccount(socialAccount)

            if accountEnabled {
                iconImageView.tintColor = socialAccount.tintColor
                nameLabel.textColor = socialAccount.tintColor
            }
        }
        
        if !accountEnabled {
            hideDetail()

        } else {
            if let githubWork = githubWork {
                self.githubWork = githubWork

            } else {
                if let userID = profileUser?.userID {

                    githubWorkOfUserWithUserID(userID, failureHandler: nil, completion: { githubWork in
                        //println("githubWork: \(githubWork)")

                        SafeDispatch.async { [weak self] in
                            self?.githubWork = githubWork

                            completion?(githubWork)
                        }
                    })
                }
            }
        }
    }
}


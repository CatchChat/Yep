//
//  ProfileSocialAccountImagesCell.swift
//  Yep
//
//  Created by NIX on 15/5/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import Kingfisher

class ProfileSocialAccountImagesCell: UICollectionViewCell {

    var socialWork: SocialWork? {
        didSet {
            if let work = socialWork {
                switch work {
                case .Dribbble(let dribbbleWork):
                    let shots = dribbbleWork.shots

                    if shots.count > 0 {
                        let shot = shots[0]
                        imageView1.kf_setImageWithURL(NSURL(string: shot.images.normal)!)
                    }

                    if shots.count > 1 {
                        let shot = shots[1]
                        imageView2.kf_setImageWithURL(NSURL(string: shot.images.normal)!)
                    }
                    if shots.count > 2 {
                        let shot = shots[2]
                        imageView3.kf_setImageWithURL(NSURL(string: shot.images.normal)!)
                    }

                case .Instagram(let instagramWork):
                    break
                }
            }
        }
    }

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


        if let socialWork = socialWork {
            self.socialWork = socialWork

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

                switch socialAccount {

                case .Dribbble:
                    dribbbleWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                        defaultFailureHandler(reason, errorMessage)

                    }, completion: { dribbbleWork in
                        println("dribbbleWork: \(dribbbleWork.shots.count)")

                        dispatch_async(dispatch_get_main_queue()) {
                            let socialWork = SocialWork.Dribbble(dribbbleWork)

                            self.socialWork = socialWork

                            completion?(socialWork)
                        }
                    })
                    
                default:
                    break
                }
            }
        }
    }
}

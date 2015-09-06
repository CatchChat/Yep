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

                accessoryImageView.hidden = false

                switch work {

                case .Dribbble(let dribbbleWork):

                    let shots = dribbbleWork.shots

                    if let shot = shots[safe: 0] {
                        imageView1.kf_setImageWithURL(NSURL(string: shot.images.teaser)!, placeholderImage: nil)
                    }

                    if let shot = shots[safe: 1] {
                        imageView2.kf_setImageWithURL(NSURL(string: shot.images.teaser)!, placeholderImage: nil)
                    }

                    if let shot = shots[safe: 2] {
                        imageView3.kf_setImageWithURL(NSURL(string: shot.images.teaser)!, placeholderImage: nil)
                    }

                case .Instagram(let instagramWork):

                    let medias = instagramWork.medias

                    if let media = medias[safe: 0] {
                        imageView1.kf_setImageWithURL(NSURL(string: media.images.thumbnail)!, placeholderImage: nil)
                    }

                    if let media = medias[safe: 1] {
                        imageView2.kf_setImageWithURL(NSURL(string: media.images.thumbnail)!, placeholderImage: nil)
                    }

                    if let media = medias[safe: 2] {
                        imageView3.kf_setImageWithURL(NSURL(string: media.images.thumbnail)!, placeholderImage: nil)
                    }
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

        let cornerRadius: CGFloat = 2
        imageView1.layer.cornerRadius = cornerRadius
        imageView2.layer.cornerRadius = cornerRadius
        imageView3.layer.cornerRadius = cornerRadius

        imageView1.clipsToBounds = true
        imageView2.clipsToBounds = true
        imageView3.clipsToBounds = true

        accessoryImageView.hidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView1.image = nil
        imageView2.image = nil
        imageView3.image = nil
    }

    func configureWithProfileUser(profileUser: ProfileUser?, socialAccount: SocialAccount, socialWork: SocialWork?, completion: ((SocialWork) -> Void)?) {

        iconImageView.image = UIImage(named: socialAccount.iconName)
        nameLabel.text = socialAccount.description

        iconImageView.tintColor = UIColor.lightGrayColor()
        nameLabel.textColor = UIColor.lightGrayColor()

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
            accessoryImageView.hidden = true

        } else {
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
                }

                if let userID = userID {

                    switch socialAccount {

                    case .Dribbble:
                        dribbbleWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                            defaultFailureHandler(reason, errorMessage)

                        }, completion: { dribbbleWork in
                            //println("dribbbleWork: \(dribbbleWork.shots.count)")

                            dispatch_async(dispatch_get_main_queue()) {
                                let socialWork = SocialWork.Dribbble(dribbbleWork)

                                self.socialWork = socialWork

                                completion?(socialWork)
                            }
                        })

                    case .Instagram:
                        instagramWorkOfUserWithUserID(userID, failureHandler: { (reason, errorMessage) -> Void in
                            defaultFailureHandler(reason, errorMessage)

                        }, completion: { instagramWork in
                            //println("instagramWork: \(instagramWork.medias.count)")

                            dispatch_async(dispatch_get_main_queue()) {
                                let socialWork = SocialWork.Instagram(instagramWork)

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
}

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
    
    var socialAccount: SocialAccount?

    var socialWork: SocialWork? {
        didSet {
            if let work = socialWork {

                accessoryImageView.hidden = false

                switch work {

                case .Dribbble(let dribbbleWork):
                    
                    if socialAccount != SocialAccount(rawValue: "dribbble") {
                        return
                    }

                    // 对于从左到右排列，且左边的最新，要处理数量不足的情况

                    var shots: [DribbbleWork.Shot?] = dribbbleWork.shots.map({ $0 })

                    let imageViews = [
                        imageView3,
                        imageView2,
                        imageView1,
                    ]

                    // 不足补空
                    if shots.count < imageViews.count {

                        let empty: [DribbbleWork.Shot?] = Array(0..<(imageViews.count - shots.count)).map({ _ in
                            return nil
                        })

                        shots.insertContentsOf(empty, at: 0)
                    }

                    for i in 0..<imageViews.count {

                        if let shot = shots[i] {
                            imageViews[i].kf_setImageWithURL(NSURL(string: shot.images.teaser)!, placeholderImage: nil, optionsInfo: MediaOptionsInfos)
                        } else {
                            imageViews[i].image = nil
                        }
                    }

                case .Instagram(let instagramWork):
                    
                    if socialAccount != SocialAccount(rawValue: "instagram") {
                        return
                    }

                    // 对于从左到右排列，且左边的最新，要处理数量不足的情况

                    var medias: [InstagramWork.Media?] = instagramWork.medias.map({ $0 })

                    let imageViews = [
                        imageView3,
                        imageView2,
                        imageView1,
                    ]

                    // 不足补空
                    if medias.count < imageViews.count {

                        let empty: [InstagramWork.Media?] = Array(0..<(imageViews.count - medias.count)).map({ _ in
                            return nil
                        })

                        medias.insertContentsOf(empty, at: 0)
                    }

                    for i in 0..<imageViews.count {

                        if let media = medias[i] {
                            imageViews[i].kf_setImageWithURL(NSURL(string: media.images.thumbnail)!, placeholderImage: nil, optionsInfo: MediaOptionsInfos)
                        } else {
                            imageViews[i].image = nil
                        }
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

        accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
        iconImageViewLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.rightEdgeInset

        imageView1.contentMode = .ScaleAspectFill
        imageView2.contentMode = .ScaleAspectFill
        imageView3.contentMode = .ScaleAspectFill

        let cornerRadius: CGFloat = 2
        imageView1.layer.cornerRadius = cornerRadius
        imageView2.layer.cornerRadius = cornerRadius
        imageView3.layer.cornerRadius = cornerRadius

        imageView1.clipsToBounds = true
        imageView2.clipsToBounds = true
        imageView3.clipsToBounds = true
        
        imageView1.kf_showIndicatorWhenLoading = true
        imageView2.kf_showIndicatorWhenLoading = true
        imageView3.kf_showIndicatorWhenLoading = true
        
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
                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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
                            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

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

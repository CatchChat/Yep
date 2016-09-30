//
//  ProfileSocialAccountImagesCell.swift
//  Yep
//
//  Created by NIX on 15/5/15.
//  Copyright (c) 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit
import Kingfisher

final class ProfileSocialAccountImagesCell: UICollectionViewCell {
    
    var socialAccount: SocialAccount?

    var socialWork: SocialWork? {
        didSet {
            if let work = socialWork {

                accessoryImageView.isHidden = false

                switch work {

                case .dribbble(let dribbbleWork):
                    
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

                        shots.insert(contentsOf: empty, at: 0)
                    }

                    for i in 0..<imageViews.count {

                        if let shot = shots[i] {
                            imageViews[i]?.kf.setImage(with: URL(string: shot.images.teaser)!, placeholder: nil, options: MediaOptionsInfos)
                        } else {
                            imageViews[i]?.image = nil
                        }
                    }

                case .instagram(let instagramWork):
                    
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

                        medias.insert(contentsOf: empty, at: 0)
                    }

                    for i in 0..<imageViews.count {

                        if let media = medias[i] {
                            imageViews[i]?.kf.setImage(with: URL(string: media.images.thumbnail)!, placeholder: nil, options: MediaOptionsInfos)
                        } else {
                            imageViews[i]?.image = nil
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

        imageView1.contentMode = .scaleAspectFill
        imageView2.contentMode = .scaleAspectFill
        imageView3.contentMode = .scaleAspectFill

        let cornerRadius: CGFloat = 2
        imageView1.layer.cornerRadius = cornerRadius
        imageView2.layer.cornerRadius = cornerRadius
        imageView3.layer.cornerRadius = cornerRadius

        imageView1.clipsToBounds = true
        imageView2.clipsToBounds = true
        imageView3.clipsToBounds = true

        /*
        imageView1.kf_showIndicatorWhenLoading = true
        imageView2.kf_showIndicatorWhenLoading = true
        imageView3.kf_showIndicatorWhenLoading = true
         */
        
        accessoryImageView.isHidden = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        imageView1.image = nil
        imageView2.image = nil
        imageView3.image = nil
    }

    func configureWithProfileUser(_ profileUser: ProfileUser?, socialAccount: SocialAccount, socialWork: SocialWork?, completion: ((SocialWork) -> Void)?) {

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
            accessoryImageView.isHidden = true

        } else {
            if let socialWork = socialWork {
                self.socialWork = socialWork

            } else {
                if let userID = profileUser?.userID {

                    switch socialAccount {

                    case .dribbble:
                        dribbbleWorkOfUserWithUserID(userID, failureHandler: nil, completion: { dribbbleWork in
                            //println("dribbbleWork: \(dribbbleWork.shots.count)")

                            SafeDispatch.async { [weak self] in
                                let socialWork = SocialWork.dribbble(dribbbleWork)
                                self?.socialWork = socialWork

                                completion?(socialWork)
                            }
                        })

                    case .instagram:
                        instagramWorkOfUserWithUserID(userID, failureHandler: nil, completion: { instagramWork in
                            //println("instagramWork: \(instagramWork.medias.count)")

                            SafeDispatch.async { [weak self] in
                                let socialWork = SocialWork.instagram(instagramWork)
                                self?.socialWork = socialWork

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


//
//  ProfileFeedsCell.swift
//  Yep
//
//  Created by nixzhu on 15/11/17.
//  Copyright © 2015年 Catch Inc. All rights reserved.
//

import UIKit
import YepKit

final class ProfileFeedsCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconImageViewLeadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var nameLabel: UILabel!

    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!

    @IBOutlet weak var accessoryImageView: UIImageView!
    @IBOutlet weak var accessoryImageViewTrailingConstraint: NSLayoutConstraint!

    fileprivate var enabled: Bool = false {
        willSet {
            if newValue {
                iconImageView.tintColor = UIColor.yepTintColor()
                nameLabel.textColor = UIColor.yepTintColor()
                accessoryImageView.isHidden = false
                accessoryImageView.tintColor = UIColor.yepCellAccessoryImageViewTintColor()
            } else {
                iconImageView.tintColor = SocialAccount.disabledColor
                nameLabel.textColor = SocialAccount.disabledColor
                accessoryImageView.isHidden = true
            }
        }
    }

    var feedAttachments: [DiscoveredAttachment?]? {
        willSet {
            guard let _attachments = newValue else {
                return
            }

            enabled = !_attachments.isEmpty

            // 对于从左到右排列，且左边的最新，要处理数量不足的情况

            var attachments = _attachments

            let imageViews = [
                imageView4,
                imageView3,
                imageView2,
                imageView1,
            ]

            let shortagesCount = max(imageViews.count - attachments.count, 0)

            // 不足补空
            if shortagesCount > 0 {
                let shortages = Array<DiscoveredAttachment?>(repeating: nil, count: shortagesCount)
                attachments.insert(contentsOf: shortages, at: 0)
            }

            for i in 0..<imageViews.count {
                if i < shortagesCount {
                    imageViews[i]?.image = nil
                } else {
                    if let thumbnailImage = attachments[i]?.thumbnailImage {
                        imageViews[i]?.image = thumbnailImage
                    } else {
                        imageViews[i]?.image = UIImage.yep_iconFeedText
                    }
                }
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        enabled = false

        nameLabel.text = String.trans_titleFeeds

        iconImageViewLeadingConstraint.constant = YepConfig.Profile.leftEdgeInset
        accessoryImageViewTrailingConstraint.constant = YepConfig.Profile.rightEdgeInset

        imageView1.contentMode = .scaleAspectFill
        imageView2.contentMode = .scaleAspectFill
        imageView3.contentMode = .scaleAspectFill
        imageView4.contentMode = .scaleAspectFill

        let cornerRadius: CGFloat = 2
        imageView1.layer.cornerRadius = cornerRadius
        imageView2.layer.cornerRadius = cornerRadius
        imageView3.layer.cornerRadius = cornerRadius
        imageView4.layer.cornerRadius = cornerRadius

        imageView1.clipsToBounds = true
        imageView2.clipsToBounds = true
        imageView3.clipsToBounds = true
        imageView4.clipsToBounds = true
    }

    func configureWithProfileUser(_ profileUser: ProfileUser?, feedAttachments: [DiscoveredAttachment?]?, completion: ((_ feeds: [DiscoveredFeed], _ feedAttachments: [DiscoveredAttachment?]) -> Void)?) {

        if let feedAttachments = feedAttachments {
            self.feedAttachments = feedAttachments

        } else {
            guard let profileUser = profileUser else {
                return
            }

            feedsOfUser(profileUser.userID, pageIndex: 1, perPage: 20, failureHandler: nil, completion: { feeds in

                let validFeeds = feeds.flatMap({ $0 })
                println("user's feeds: \(validFeeds.count)")

                let feedAttachments = validFeeds.map({ feed -> DiscoveredAttachment? in
                    if let attachment = feed.attachment {
                        if case let .images(attachments) = attachment {
                            return attachments.first
                        }
                    }

                    return nil
                })

                SafeDispatch.async { [weak self] in
                    self?.feedAttachments = feedAttachments

                    completion?(validFeeds, feedAttachments)
                }
            })
        }
    }
}

